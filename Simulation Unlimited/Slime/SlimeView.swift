//
//  SlimeView.swift
//  SlimeUnlimited
//
//  Created by Robert Waltham on 2022-07-23.
//

import Foundation
import MetalKit
import SwiftUI
import simd

struct SlimeView: UIViewRepresentable {
    
    @State var viewModel: SlimeViewModel
    
    typealias UIViewType = MTKView
    
    init(viewModel: SlimeViewModel) {
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
        fileprivate var viewModel: SlimeViewModel!
        private var metalDevice: MTLDevice!
        private var metalCommandQueue: MTLCommandQueue!
        
        private var pathTextures: [MTLTexture] = []
        private var states: [MTLComputePipelineState] = []
        private var particleBuffer: MTLBuffer!
        private var configBuffer: MTLBuffer!
        private var viewPortSize = vector_uint2(x: 0, y: 0)
        
        private var particles = [SlimeParticle]()
        private var colours = RenderColours()
        
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
        
        init(_ parent: SlimeView) {
            
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

extension SlimeView.Coordinator {
    
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

extension SlimeView.Coordinator {
    
    func wave(time: Double, phase: Double, phaseOffset: Double, magitude: Double, magnitudeOffset: Double) -> Float {
        return Float((sin(time * phase + phaseOffset) + magnitudeOffset) * magitude)
    }
    
    func draw() {
        
        initializeParticlesIfNeeded()
        initializeConfigBufferIfNeeded()
        
        configBuffer.contents().copyMemory(from: [viewModel.redConfig.config, viewModel.greenConfig.config, viewModel.blueConfig.config], byteCount: 3 * MemoryLayout<SlimeConfig>.size)

        
        if viewModel.resetOnNext {
            resetParticles()
            viewModel.resetOnNext = false
        }
        
        if pathTextures.count == 0 {
            pathTextures.append(makeTexture(device: metalDevice, drawableSize: viewPortSize))
            pathTextures.append(makeTexture(device: metalDevice, drawableSize: viewPortSize))
        }
        let randomCount = 1024
        var random: [Float] = (0..<randomCount).map { _ in Float.random(in: 0...1) }
        
        let threadgroupSizeMultiplier = 1
        let maxThreads = 512
        let particleThreadsPerGroup = MTLSize(width: maxThreads, height: 1, depth: 1)
        let particleThreadGroupsPerGrid = MTLSize(width: (max(viewModel.particleCount / (maxThreads * threadgroupSizeMultiplier), 1)), height: 1, depth:1)
        
        let w = states[0].threadExecutionWidth
        let h = states[0].maxTotalThreadsPerThreadgroup / w
        let textureThreadsPerGroup = MTLSizeMake(w, h, 1)
        let textureThreadgroupsPerGrid = MTLSize(width: (Int(viewPortSize.x) + w - 1) / w, height: (Int(viewPortSize.y) + h - 1) / h, depth: 1)
        
        
        if let commandBuffer = metalCommandQueue.makeCommandBuffer(),
           let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
            
            commandEncoder.setTexture(pathTextures[0], index: Int(InputTextureIndexPathInput.rawValue))
            commandEncoder.setTexture(pathTextures[1], index: Int(InputTextureIndexPathOutput.rawValue))
            commandEncoder.setBuffer(configBuffer, offset: 0, index: Int(InputIndexConfig.rawValue))
            commandEncoder.setBytes(&random, length: MemoryLayout<Float>.stride * randomCount, index: Int(InputIndexRandom.rawValue))
            
            if let particleBuffer = particleBuffer {
                
                // update particles and draw on path
                commandEncoder.setComputePipelineState(states[1])
                commandEncoder.setBuffer(particleBuffer, offset: 0, index: Int(InputIndexParticles.rawValue))
                commandEncoder.setBytes(&viewModel.particleCount, length: MemoryLayout<Int>.stride, index: Int(InputIndexParticleCount.rawValue))
                commandEncoder.setBytes(&colours, length: MemoryLayout<RenderColours>.stride, index: Int(InputIndexColours.rawValue))
                commandEncoder.dispatchThreadgroups(particleThreadGroupsPerGrid, threadsPerThreadgroup: particleThreadsPerGroup)
                
                // blur path and copy to second path buffer
                commandEncoder.setComputePipelineState(states[4])
                commandEncoder.dispatchThreadgroups(textureThreadgroupsPerGrid, threadsPerThreadgroup: textureThreadsPerGroup)
            }
            
            if let drawable = view?.currentDrawable {
                
                // Draw Background Colour
                commandEncoder.setComputePipelineState(states[0])
                commandEncoder.setTexture(drawable.texture, index: Int(InputTextureIndexDrawable.rawValue))
                commandEncoder.dispatchThreadgroups(textureThreadgroupsPerGrid, threadsPerThreadgroup: textureThreadsPerGroup)
                
                if viewModel.drawPath {
                    commandEncoder.setComputePipelineState(states[3])
                    commandEncoder.dispatchThreadgroups(textureThreadgroupsPerGrid, threadsPerThreadgroup: textureThreadsPerGroup)
                }
                
                if viewModel.drawParticles, let particleBuffer = particleBuffer {
                    commandEncoder.setComputePipelineState(states[2])
                    commandEncoder.setBuffer(particleBuffer, offset: 0, index: Int(InputIndexParticleCount.rawValue))
                    commandEncoder.dispatchThreadgroups(particleThreadGroupsPerGrid, threadsPerThreadgroup: particleThreadsPerGroup)
                }
                
                commandEncoder.endEncoding()
                commandBuffer.present(drawable)
                
            } else {
                fatalError("no drawable")
            }
            commandBuffer.addCompletedHandler { buffer in
                self.pathTextures.reverse()
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
        
        states = try ["firstPassSlime", "secondPassSlime", "thirdPassSlime", "fourthPassSlime", "boxBlur"].map {
            guard let function = library.makeFunction(name: $0) else {
                fatalError("Can't make function \($0)")
            }
            return try device.makeComputePipelineState(function: function)
        }
    }
    
    private func initializeConfigBufferIfNeeded() {
        guard configBuffer == nil else {
            return
        }
            
        configBuffer = metalDevice.makeBuffer(length: 3 * MemoryLayout<SlimeConfig>.size)
    }
    
    
    private func initializeParticlesIfNeeded() {
        
        guard particleBuffer == nil else {
            return
        }
        
        particles = makeParticles()
        let size = particles.count * MemoryLayout<Particle>.size
        
        particleBuffer = metalDevice.makeBuffer(bytes: &particles, length: size, options: [])
        particleBuffer.contents().copyMemory(from: &particles, byteCount: size)
    }
    
    private func resetParticles() {
        
        guard particleBuffer != nil else {
            return
        }
        
        let size = particles.count * MemoryLayout<Particle>.size
        particles = makeParticles()
        particleBuffer.contents().copyMemory(from: &particles, byteCount: size)
    }
    
    private func extractParticles() {
        
        guard particleBuffer != nil else {
            return
        }
        
        particles = []
        for i in 0..<viewModel.particleCount {
            particles.append((particleBuffer.contents() + (i * MemoryLayout<SlimeParticle>.size)).load(as: SlimeParticle.self))
        }
    }
    
    private func makeParticles() -> [SlimeParticle] {
        
        var result = [SlimeParticle]()
        
        let speedRange = SlimeConfig.minSpeed...SlimeConfig.maxSpeed
        let xRange = viewModel.margin...(Float(viewPortSize.x) - viewModel.margin)
        let yRange = viewModel.margin...(Float(viewPortSize.y) - viewModel.margin)
        let lineSpace: Float = 100
        
        for i in 0 ..< viewModel.particleCount {
            var speed = SIMD2<Float>(Float.random(in: speedRange), 0)
            var species = Float(Int.random(in: 0..<3))
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
                species = xLinePosition.truncatingRemainder(dividingBy: 3)
            }
            
            let particle = SlimeParticle(position: position, velocity: speed, species: species)
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
    
}

struct RenderColours {
    var background = SIMD4<Float>(0,0,0,0)
    var trail = SIMD4<Float>(0.25,0.25,0.25,1)
    var particle = SIMD4<Float>(0.5,0.5,0.5,1)
}


#Preview {
    SlimeView(viewModel: SlimeViewModel())
}

private struct SlimeParticle {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var acceleration: SIMD2<Float> = SIMD2<Float>(0,0)
    var species: Float
    var bytes: Float = 0
    
    var description: String {
        return "p<\(position.x),\(position.y)> v<\(velocity.x),\(velocity.y)> a<\(acceleration.x),\(acceleration.y)"
    }
}

