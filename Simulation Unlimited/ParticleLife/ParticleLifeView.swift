//
//  ParticleLifeView.swift
//  SlimeUnlimited
//
//  Created by Robert Waltham on 2022-07-23.
//

import Foundation
import MetalKit
import SwiftUI
import simd

struct ParticleLifeView: UIViewRepresentable {
    
    @State var viewModel: ParticleLifeViewModel
    
    typealias UIViewType = MTKView
    
    init(viewModel: ParticleLifeViewModel) {
        self.viewModel = viewModel
    }
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        
        mtkView.enableSetNeedsDisplay = true
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        mtkView.drawableSize = mtkView.frame.size
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.isMultipleTouchEnabled = true
        context.coordinator.view = mtkView
        context.coordinator.viewModel = viewModel
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.viewModel = viewModel
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator : NSObject, MTKViewDelegate {
        
        fileprivate var view: MTKView?
        fileprivate var viewModel: ParticleLifeViewModel!
        private var metalDevice: MTLDevice!
        private var metalCommandQueue: MTLCommandQueue!
        
        private var pathTextures: [MTLTexture] = []
        private var pathBlurScratchTexture: MTLTexture?
        private var gradientTexture: MTLTexture?
        private var gradientNoiseSignature: ParticleLifeGradientNoiseSignature?
        private var pipelines: ParticleLifePipelineStates!
        private var particleBuffer: MTLBuffer!
        private var nextParticleBuffer: MTLBuffer!
        private var gridCountsBuffer: MTLBuffer!
        private var gridParticleIndicesBuffer: MTLBuffer!
        private var gridSignature: ParticleLifeGridSignature?
        private var colorBuffer: MTLBuffer!

        private var viewPortSize = vector_uint2(x: 0, y: 0)
        
        private var particles = [LifeParticle]()
        private var touches = [ParticleLifeTouch]()
        
        private var lastDraw = Date()
        
        private var skipDraw = false // skip all rendering, in the case the hardware doesn't support what we're doing (like in previews)
        
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            viewPortSize = vector_uint2(x: UInt32(size.width), y: UInt32(size.height))
        }
        
        func draw(in view: MTKView) {
            
            guard !skipDraw else {
                return
            }
            
            self.view = view
            
            draw()
        }
        
        init(_ parent: ParticleLifeView) {
            
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            
            super.init()
            
            guard self.metalDevice.supportsFamily(.common3) || self.metalDevice.supportsFamily(.apple4) else {
                print("doesn't support read_write textures")
                skipDraw = true
                return
            }
            
            buildPipeline()
        }
    }
}

// MARK: - Touches

extension ParticleLifeView.Coordinator {
    
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
}

// MARK: - Coordinator

extension ParticleLifeView.Coordinator {
    
    func draw() {

        
        initializeParticlesIfNeeded()
        initializeColorsIfNeeded()
        let shouldGenerateGradientTexture = updateGradientTextureIfNeeded()
        
        if viewModel.resetOnNext {
            resetParticles()
            viewModel.resetOnNext = false
        }
        
        if pathTextures.count == 0 {
            pathTextures.append(makeTexture(device: metalDevice, drawableSize: viewPortSize))
            pathTextures.append(makeTexture(device: metalDevice, drawableSize: viewPortSize))
        }
        if pathBlurScratchTexture == nil {
            pathBlurScratchTexture = makeTexture(device: metalDevice, drawableSize: viewPortSize)
        }
        touches = viewModel.touches.values.map {
            var touch = ParticleLifeTouch()
            touch.position = SIMD2<Float>(
                Float($0.x * UIScreen.main.scale),
                Float($0.y * UIScreen.main.scale)
            )
            return touch
        }
        let particleThreadsPerGroupCount = pipelines.particleThreadsPerThreadgroup
        let particleThreadsPerGroup = MTLSize(width: particleThreadsPerGroupCount, height: 1, depth: 1)
        let particleThreadGroupsPerGrid = MTLSize(
            width: max((viewModel.particleCount + particleThreadsPerGroupCount - 1) / particleThreadsPerGroupCount, 1),
            height: 1,
            depth: 1
        )
        
        let w = pipelines.background.threadExecutionWidth
        let h = pipelines.background.maxTotalThreadsPerThreadgroup / w
        let textureThreadsPerGroup = MTLSizeMake(w, h, 1)
        let textureThreadgroupsPerGrid = MTLSize(width: (Int(viewPortSize.x) + w - 1) / w, height: (Int(viewPortSize.y) + h - 1) / h, depth: 1)
        
        var colors = RenderColours()
        
        if let commandBuffer = metalCommandQueue.makeCommandBuffer(),
           let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
            
            commandEncoder.setTexture(pathTextures[0], index: Int(InputTextureIndexPathInput.rawValue))
            commandEncoder.setTexture(pathTextures[1], index: Int(InputTextureIndexPathOutput.rawValue))
            commandEncoder.setTexture(pathBlurScratchTexture, index: Int(InputTextureIndexPathScratch.rawValue))
            commandEncoder.setTexture(gradientTexture, index: Int(InputTextureIndexGradient.rawValue))
            commandEncoder.setBytes(&viewModel.config, length: MemoryLayout<ParticleLifeConfig>.stride, index: Int(ParticleLifeInputIndexConfig.rawValue))
            commandEncoder.setBytes(&colors, length: MemoryLayout<RenderColours>.stride, index: Int(ParticleLifeInputIndexRenderColours.rawValue))
            var gradientConfig = viewModel.gradientNoiseSettings.shaderConfig()
            commandEncoder.setBytes(&gradientConfig, length: MemoryLayout<ParticleLifeGradientConfig>.stride, index: Int(ParticleLifeInputIndexGradientConfig.rawValue))
            
            if shouldGenerateGradientTexture, let gradientTexture = gradientTexture {
                commandEncoder.setComputePipelineState(pipelines.generateGradientNoise)
                commandEncoder.setTexture(gradientTexture, index: Int(InputTextureIndexGradient.rawValue))
                let w = pipelines.generateGradientNoise.threadExecutionWidth
                let h = pipelines.generateGradientNoise.maxTotalThreadsPerThreadgroup / w
                let gradientThreadsPerGroup = MTLSizeMake(w, h, 1)
                let gradientThreadgroupsPerGrid = MTLSize(
                    width: (gradientTexture.width + w - 1) / w,
                    height: (gradientTexture.height + h - 1) / h,
                    depth: 1
                )
                commandEncoder.dispatchThreadgroups(gradientThreadgroupsPerGrid, threadsPerThreadgroup: gradientThreadsPerGroup)
            }

            if let particleBuffer = particleBuffer, let nextParticleBuffer = nextParticleBuffer {
                var gridConfig = updateParticleGridBuffersIfNeeded()
                var particleCount = Int32(viewModel.particleCount)
                
                commandEncoder.setBuffer(particleBuffer, offset: 0, index: Int(ParticleLifeInputIndexParticles.rawValue))
                commandEncoder.setBytes(&particleCount, length: MemoryLayout<Int32>.stride, index: Int(ParticleLifeInputIndexParticleCount.rawValue))
                commandEncoder.setBuffer(gridCountsBuffer, offset: 0, index: Int(ParticleLifeInputIndexGridCounts.rawValue))
                commandEncoder.setBuffer(gridParticleIndicesBuffer, offset: 0, index: Int(ParticleLifeInputIndexGridParticleIndices.rawValue))
                commandEncoder.setBytes(&gridConfig, length: MemoryLayout<ParticleLifeGridConfig>.stride, index: Int(ParticleLifeInputIndexGridConfig.rawValue))
                
                // build particle grid
                commandEncoder.setComputePipelineState(pipelines.clearGrid)
                let gridThreadsPerGroup = MTLSize(width: 256, height: 1, depth: 1)
                let gridThreadGroupsPerGrid = MTLSize(
                    width: max((Int(gridConfig.cellCount) + gridThreadsPerGroup.width - 1) / gridThreadsPerGroup.width, 1),
                    height: 1,
                    depth: 1
                )
                commandEncoder.dispatchThreadgroups(gridThreadGroupsPerGrid, threadsPerThreadgroup: gridThreadsPerGroup)
                commandEncoder.memoryBarrier(scope: .buffers)
                
                commandEncoder.setComputePipelineState(pipelines.buildGrid)
                commandEncoder.dispatchThreadgroups(particleThreadGroupsPerGrid, threadsPerThreadgroup: particleThreadsPerGroup)
                commandEncoder.memoryBarrier(scope: .buffers)
                
                // update particles
                commandEncoder.setComputePipelineState(pipelines.updateParticles)
                commandEncoder.setBuffer(nextParticleBuffer, offset: 0, index: Int(ParticleLifeInputIndexParticleOutput.rawValue))
                commandEncoder.setBuffer(colorBuffer, offset: 0, index: Int(ParticleLifeInputIndexSpeciesColours.rawValue))
                commandEncoder.setBytes(viewModel.weights, length: MemoryLayout<Float>.stride * viewModel.weights.count, index: Int(ParticleLifeInputIndexWeights.rawValue))
                if touches.isEmpty {
                    var touch = ParticleLifeTouch()
                    commandEncoder.setBytes(&touch, length: MemoryLayout<ParticleLifeTouch>.stride, index: Int(ParticleLifeInputIndexTouches.rawValue))
                } else {
                    commandEncoder.setBytes(touches, length: MemoryLayout<ParticleLifeTouch>.stride * touches.count, index: Int(ParticleLifeInputIndexTouches.rawValue))
                }
                var touchCount = Int32(touches.count)
                commandEncoder.setBytes(&touchCount, length: MemoryLayout<Int32>.stride, index: Int(ParticleLifeInputIndexTouchCount.rawValue))
                
                commandEncoder.dispatchThreadgroups(particleThreadGroupsPerGrid, threadsPerThreadgroup: particleThreadsPerGroup)
                
                // draw particle trails on path
                commandEncoder.setComputePipelineState(pipelines.drawTrail)
                commandEncoder.setBuffer(nextParticleBuffer, offset: 0, index: Int(ParticleLifeInputIndexParticles.rawValue))
                commandEncoder.dispatchThreadgroups(particleThreadGroupsPerGrid, threadsPerThreadgroup: particleThreadsPerGroup)
                
                // blur path and copy to second path buffer
                commandEncoder.setComputePipelineState(pipelines.blurHorizontal)
                commandEncoder.dispatchThreadgroups(textureThreadgroupsPerGrid, threadsPerThreadgroup: textureThreadsPerGroup)
                commandEncoder.memoryBarrier(scope: .textures)
                
                commandEncoder.setComputePipelineState(pipelines.blurVertical)
                commandEncoder.dispatchThreadgroups(textureThreadgroupsPerGrid, threadsPerThreadgroup: textureThreadsPerGroup)
            }
            
            if let drawable = view?.currentDrawable {
                
                // Draw Background Colour
                commandEncoder.setComputePipelineState(pipelines.background)
                commandEncoder.setTexture(drawable.texture, index: Int(InputTextureIndexDrawable.rawValue))
                commandEncoder.setTexture(gradientTexture, index: Int(InputTextureIndexGradient.rawValue))
                commandEncoder.dispatchThreadgroups(textureThreadgroupsPerGrid, threadsPerThreadgroup: textureThreadsPerGroup)
                
                if viewModel.drawPath {
                    commandEncoder.setComputePipelineState(pipelines.drawPath)
                    commandEncoder.dispatchThreadgroups(textureThreadgroupsPerGrid, threadsPerThreadgroup: textureThreadsPerGroup)
                }
                
                if viewModel.drawParticles, let nextParticleBuffer = nextParticleBuffer {
                    commandEncoder.setComputePipelineState(pipelines.drawParticles)
                    commandEncoder.setBuffer(nextParticleBuffer, offset: 0, index: Int(ParticleLifeInputIndexParticles.rawValue))
                    commandEncoder.dispatchThreadgroups(particleThreadGroupsPerGrid, threadsPerThreadgroup: particleThreadsPerGroup)
                }
                
                commandEncoder.endEncoding()
                commandBuffer.present(drawable)
                
            } else {
                fatalError("no drawable")
            }
            commandBuffer.addCompletedHandler { buffer in
                self.pathTextures.reverse()
                swap(&self.particleBuffer, &self.nextParticleBuffer)
                Task { @MainActor in
                    self.viewModel.fpsCounter.frameDidRender()
                }
            }
            commandBuffer.commit()
        }
    }
    
    func buildPipeline() {
        
        // make Command queue
        guard let queue = metalDevice.makeCommandQueue() else {
            fatalError("can't make queue")
        }
        metalCommandQueue = queue
        
        // pipeline state
        do {
            try buildRenderPipelineWithDevice(device: metalDevice)
        } catch {
            fatalError("Unable to compile render pipeline state.  Error info: \(error)")
        }
    }
    
    
    func buildRenderPipelineWithDevice(device: MTLDevice) throws {
        /// Build a render state pipeline object
        
        guard let library = device.makeDefaultLibrary() else {
            fatalError("can't create libray")
        }
        
        pipelines = try ParticleLifePipelineStates(device: device, library: library)
    }
    
    
    private func initializeParticlesIfNeeded() {
        
        guard particleBuffer == nil else {
            return
        }
        
        particles = makeParticles()
        let size = particles.count * MemoryLayout<LifeParticle>.stride
        
        particleBuffer = metalDevice.makeBuffer(bytes: particles, length: size, options: [])
        nextParticleBuffer = metalDevice.makeBuffer(bytes: particles, length: size, options: [])
    }
    
    private func resetParticles() {
        
        guard particleBuffer != nil, nextParticleBuffer != nil else {
            return
        }
        
        particles = makeParticles()
        let size = particles.count * MemoryLayout<LifeParticle>.stride
        particleBuffer.contents().copyMemory(from: particles, byteCount: size)
        nextParticleBuffer.contents().copyMemory(from: particles, byteCount: size)
    }
    
    private func extractParticles() {
        
        guard particleBuffer != nil else {
            return
        }
        
        particles = []
        for i in 0..<viewModel.particleCount {
            particles.append((particleBuffer.contents() + (i * MemoryLayout<LifeParticle>.stride)).load(as: LifeParticle.self))
        }
    }
    
    private func initializeColorsIfNeeded() {
        
        guard colorBuffer == nil else {
            return
        }
        
        let count = viewModel.colours.count
        let size = count * MemoryLayout<SIMD4<Float>>.size
        
        colorBuffer = metalDevice.makeBuffer(bytes: viewModel.colours, length: size, options: [])
    }
    
    private func updateParticleGridBuffersIfNeeded() -> ParticleLifeGridConfig {
        let cellSize: Float = 32
        let maxParticlesPerCell = 128
        let gridWidth = max(Int(ceil(Float(viewPortSize.x) / cellSize)), 1)
        let gridHeight = max(Int(ceil(Float(viewPortSize.y) / cellSize)), 1)
        let cellCount = gridWidth * gridHeight
        let signature = ParticleLifeGridSignature(
            gridWidth: gridWidth,
            gridHeight: gridHeight,
            maxParticlesPerCell: maxParticlesPerCell
        )
        
        if gridSignature != signature {
            gridCountsBuffer = metalDevice.makeBuffer(
                length: cellCount * MemoryLayout<UInt32>.stride,
                options: .storageModePrivate
            )
            gridParticleIndicesBuffer = metalDevice.makeBuffer(
                length: cellCount * maxParticlesPerCell * MemoryLayout<UInt32>.stride,
                options: .storageModePrivate
            )
            gridSignature = signature
        }
        
        var config = ParticleLifeGridConfig()
        config.gridWidth = Int32(gridWidth)
        config.gridHeight = Int32(gridHeight)
        config.cellCount = Int32(cellCount)
        config.maxParticlesPerCell = Int32(maxParticlesPerCell)
        config.cellRadius = Int32(max(ceil(viewModel.config.rMaxDistance / cellSize), 1))
        config.cellSize = cellSize
        return config
    }
    
    private func updateGradientTextureIfNeeded() -> Bool {
        let signature = ParticleLifeGradientNoiseSignature(settings: viewModel.gradientNoiseSettings)
        guard gradientTexture == nil || gradientNoiseSignature != signature else {
            return false
        }
        
        let size = max(viewModel.gradientNoiseSettings.textureSize, 2)
        if gradientTexture == nil || gradientTexture?.width != size || gradientTexture?.height != size || gradientTexture?.pixelFormat != .rgba8Unorm {
            gradientTexture = makeGradientTexture(device: metalDevice, size: size)
        }
        
        gradientNoiseSignature = signature
        return true
    }
    
    private func makeParticles() -> [LifeParticle] {
        
        var result = [LifeParticle]()
        
        let speedRange = viewModel.minSpeed...viewModel.maxSpeed
        let xRange = viewModel.margin...(Float(viewPortSize.x) - viewModel.margin)
        let yRange = viewModel.margin...(Float(viewPortSize.y) - viewModel.margin)
        let lineSpace: Float = 100
        
        for i in 0 ..< viewModel.particleCount {
            var speed = SIMD2<Float>(Float.random(in: speedRange), 0)
            var species = Int32.random(in: 0..<Int32(viewModel.config.flavourCount))
            let position: SIMD2<Float>
            
            switch viewModel.startType {
                
            case .random:
                position = SIMD2<Float>(Float.random(in: xRange), Float.random(in: yRange))
                let angle = Float.random(in: 0...Float.pi * 2)
                let rotation = simd_float2x2(SIMD2<Float>(cos(angle), -sin(angle)), SIMD2<Float>(sin(angle), cos(angle)))
                speed = rotation * speed
                
            case .circle:
                position = SIMD2<Float>(Float(viewPortSize.x / 2), Float(viewPortSize.y / 2))
                let angle = Float.random(in: 0...Float.pi * 2)
                
                let rotation = simd_float2x2(SIMD2<Float>(cos(angle), -sin(angle)), SIMD2<Float>(sin(angle), cos(angle)))
                speed = rotation * speed
                
            case .grid:
                
                if i < viewModel.particleCount / 2 {
                    
                    let xLinePosition = round(Float.random(in: xRange) / lineSpace)
                    let xPosition = xLinePosition * lineSpace
                    position = SIMD2<Float>(xPosition, Float.random(in: yRange))
                    speed = SIMD2<Float>(0, Float.random(in: speedRange))
                    species = 0
                } else {
                    
                    let yLinePosition = round(Float.random(in: yRange) / lineSpace)
                    let yPosition = yLinePosition * lineSpace
                    position = SIMD2<Float>(Float.random(in: xRange), yPosition)
                    speed = SIMD2<Float>(Float.random(in: speedRange), 0)
                    species = 1
                }
                
            case.lines:
                
                let xLinePosition = round(Float.random(in: xRange) / lineSpace)
                let xPosition = xLinePosition * lineSpace
                position = SIMD2<Float>(xPosition, Float.random(in: yRange))
                speed = SIMD2<Float>(0, Float.random(in: speedRange))
                if i % 2 == 0 {
                    speed.y *= -1
                }
                species = Int32(xLinePosition.truncatingRemainder(dividingBy: 3))
            }
            
            var particle = LifeParticle()
            particle.position = position
            particle.velocity = speed
            particle.acceleration = SIMD2<Float>(0,0)
            particle.species = species
            particle.bytes = 0
            result.append(particle)
        }
        return result
    }
    
    private func makeTexture(device: MTLDevice, drawableSize: vector_uint2) -> MTLTexture {
        let descriptor = MTLTextureDescriptor()
        
        descriptor.storageMode = .private
        descriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderWrite.rawValue | MTLTextureUsage.shaderRead.rawValue)
        descriptor.width = Int(drawableSize.x)
        descriptor.height = Int(drawableSize.y)
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            fatalError("can't make texture")
        }
        
        return texture
    }
    
    private func makeGradientTexture(device: MTLDevice, size: Int) -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: size,
            height: size,
            mipmapped: false
        )
        descriptor.storageMode = .private
        descriptor.usage = [.shaderRead, .shaderWrite]
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            fatalError("can't make gradient texture")
        }
        
        return texture
    }
    
}

struct ParticleLifeColors {
    var background = SIMD4<Float>(0,0,0,0)
    var trail = SIMD4<Float>(0.25,0.25,0.25,1)
    var particle = SIMD4<Float>(0.5,0.5,0.5,1)
}

private struct ParticleLifeGridSignature: Equatable {
    let gridWidth: Int
    let gridHeight: Int
    let maxParticlesPerCell: Int
}

private struct ParticleLifePipelineStates {
    let generateGradientNoise: MTLComputePipelineState
    let background: MTLComputePipelineState
    let clearGrid: MTLComputePipelineState
    let buildGrid: MTLComputePipelineState
    let updateParticles: MTLComputePipelineState
    let drawTrail: MTLComputePipelineState
    let drawParticles: MTLComputePipelineState
    let drawPath: MTLComputePipelineState
    let blurHorizontal: MTLComputePipelineState
    let blurVertical: MTLComputePipelineState
    let particleThreadsPerThreadgroup: Int
    
    init(device: MTLDevice, library: MTLLibrary) throws {
        generateGradientNoise = try Self.makePipeline(named: "generateParticleLifeGradientNoise", device: device, library: library)
        background = try Self.makePipeline(named: "drawParticleLifeBackground", device: device, library: library)
        clearGrid = try Self.makePipeline(named: "clearParticleLifeGrid", device: device, library: library)
        buildGrid = try Self.makePipeline(named: "buildParticleLifeGrid", device: device, library: library)
        updateParticles = try Self.makePipeline(named: "updateParticles", device: device, library: library)
        drawTrail = try Self.makePipeline(named: "drawParticleTrail", device: device, library: library)
        drawParticles = try Self.makePipeline(named: "drawLifeParticles", device: device, library: library)
        drawPath = try Self.makePipeline(named: "drawParticleLifePath", device: device, library: library)
        blurHorizontal = try Self.makePipeline(named: "boxBlurHorizontal", device: device, library: library)
        blurVertical = try Self.makePipeline(named: "boxBlurVertical", device: device, library: library)
        particleThreadsPerThreadgroup = [
            updateParticles.maxTotalThreadsPerThreadgroup,
            drawTrail.maxTotalThreadsPerThreadgroup,
            drawParticles.maxTotalThreadsPerThreadgroup,
            buildGrid.maxTotalThreadsPerThreadgroup,
        ].min() ?? 1
    }
    
    private static func makePipeline(named name: String, device: MTLDevice, library: MTLLibrary) throws -> MTLComputePipelineState {
        guard let function = library.makeFunction(name: name) else {
            fatalError("Can't make function \(name)")
        }
        return try device.makeComputePipelineState(function: function)
    }
}


#Preview {
    ParticleLifeView(viewModel: ParticleLifeViewModel())
}

extension LifeParticle: CustomStringConvertible {
    public var description: String {
        return "p<\(position.x),\(position.y)> v<\(velocity.x),\(velocity.y)> a<\(acceleration.x),\(acceleration.y)"
    }
}
