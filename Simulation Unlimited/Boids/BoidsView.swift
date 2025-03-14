//
//  BoidsView.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2023-09-29.
//

import SwiftUI

import Foundation
import MetalKit
import Metal
import SwiftUI

struct BoidsView: UIViewRepresentable {
    
    typealias UIViewType = MTKView
    
    @State var viewModel = BoidsViewModel()
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        
        let coordinator = context.coordinator
        
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.drawableSize = mtkView.frame.size
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = false
        mtkView.preferredFramesPerSecond = 30
        mtkView.isMultipleTouchEnabled = true
        coordinator.view = mtkView
        coordinator.buildPipeline()
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.viewModel = viewModel
    }
    
    func makeCoordinator() -> Coordinator {
        BoidsView.Coordinator(self)
    }
    
    class Coordinator : NSObject, MTKViewDelegate {
        
        var view: MTKView! // TODO: view with touches
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        fileprivate var states: BoidsPipelineStates!
        
        private var pathTextures: [MTLTexture] = []
        var particleBuffer: MTLBuffer!
        var configBuffer: MTLBuffer!
        var blurBuffer: MTLBuffer!
        var viewPortSize: vector_uint2 = vector_uint2(x: 0, y: 0)
        
        var particles = [Particle]()
        var obstacles = [Obstacle]()
        
        var viewModel: BoidsViewModel
        
        var triangleMesh: MTLBuffer!
        
        init(_ parent: BoidsView) {
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            self.viewModel = parent.viewModel
            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            drawableSizeWillChange(size)
        }
        
        func draw(in view: MTKView) {
            draw()
        }
    }
}

struct Particle {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var acceleration: SIMD2<Float> = SIMD2<Float>(0,0)
    var force: SIMD2<Float> = SIMD2<Float>(0,0)
    var species: Int
    var variance: Float
    var padding: Float = 0
    
    var description: String {
        return "p<\(position.x),\(position.y)> v<\(velocity.x),\(velocity.y)> a<\(acceleration.x),\(acceleration.y) f<\(force.x),\(force.y)>"
    }
}

struct Obstacle {
    var position: SIMD2<Float>
}


extension BoidsView.Coordinator {
    
    func obstacleBuffer() -> MTLBuffer {
        
        if obstacles.count == 0 {
            obstacles.append(Obstacle(position: SIMD2<Float>(0,0)))
        }
        
        let size = obstacles.count * MemoryLayout<Obstacle>.size
        guard let buffer = metalDevice.makeBuffer(bytes: &obstacles, length: size, options: []) else {
            fatalError("can't make buffer")
        }
        return buffer
    }
    
    func initializeBoidsIfNeeded() {
        
        guard particleBuffer == nil else {
            return
        }
        let maxSpeed = viewModel.redConfig.max_speed
        
        for _ in 0 ..< viewModel.count {
            let speed = SIMD2<Float>(
                Float.random(in: -maxSpeed...maxSpeed),
                Float.random(in: -maxSpeed...maxSpeed)
            )
            let position = SIMD2<Float>(
                randomPosition(length: UInt(viewPortSize.x)),
                randomPosition(length: UInt(viewPortSize.y))
            )
            let particle = Particle(position: position,
                                    velocity: speed,
                                    species: Int.random(in: 0...2),
                                    variance: Float.random(in: -1...1))
            particles.append(particle)
        }
        let size = particles.count * MemoryLayout<Particle>.size
        particleBuffer = metalDevice
            .makeBuffer(bytes: &particles, length: size, options: [])
        
        triangleMesh = makeTriangle(device: metalDevice)
        
    }
    
    func initializeConfigBufferIfNeeded() {
        guard configBuffer == nil else {
            return
        }
        
        configBuffer = metalDevice.makeBuffer(length: 3 * MemoryLayout<BoidsConfig>.size)
        
        guard blurBuffer == nil else {
            return
        }
        
        blurBuffer = metalDevice.makeBuffer(length: MemoryLayout<BlurConfig>.size)
    }
    
    private func randomPosition(length: UInt) -> Float {
        let maxSize = length - (UInt(viewModel.greenConfig.margin) * 2)
        return Float(
            arc4random_uniform(UInt32(maxSize)) + UInt32(
                viewModel.redConfig.margin
            )
        )
    }
    
    func buildPipeline() {
        
        // make Command queue
        guard let queue = metalDevice.makeCommandQueue() else {
            fatalError("can't make queue")
        }
        metalCommandQueue = queue
        
        
        // pipeline state
        do {
            try buildRenderPipelineWithDevice(
                device: metalDevice,
                metalKitView: view
            )
        } catch {
            fatalError(
                "Unable to compile render pipeline state.  Error info: \(error)"
            )
        }
        
    }
    
    func buildRenderPipelineWithDevice(device: MTLDevice, metalKitView: MTKView) throws {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("can't create libray")
        }
        
        states = BoidsPipelineStates(library: library, device: device)
    }
    
    func buildRenderPassDescriptor(target: MTLTexture) -> MTLRenderPassDescriptor {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = target
        descriptor.colorAttachments[0].loadAction = .load;
        descriptor.colorAttachments[0].storeAction = .store;
//        descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2, 0.5, 0.95, 1.0);
        
        return descriptor
    }
    
    func makeTriangle(device: MTLDevice) -> MTLBuffer {
        
        let vertices : [Vertex] = [
            Vertex(position: [-0.75, -0.75, 0.0, 1.0], color: [1, 1, 1]),
            Vertex(position: [ 0.75, -0.75, 0.0, 1.0], color: [1, 1, 1]),
            Vertex(position: [  0.0,  0.75, 0.0, 1.0], color: [1, 1, 1])
        ]
        
        return device.makeBuffer(bytes: vertices,
                                 length: vertices.count * MemoryLayout<Vertex>.stride,
                                 options: [])!
    }
    
    func extractParticles() {
        
        guard particleBuffer != nil else {
            return
        }
        
        particles = []
        for i in 0..<viewModel.count {
            particles
                .append(
                    (particleBuffer.contents() + (i * MemoryLayout<Particle>.size)).load(
                        as: Particle.self
                    )
                )
        }
    }
    
    // MARK: - UIViewRepresentable.Coordinator
    
    func drawableSizeWillChange(_ size: CGSize) {
        /// Respond to drawable size or orientation changes here
        viewPortSize = vector_uint2(
            x: UInt32(size.width),
            y: UInt32(size.height)
        )
    }
    
    private func makeTexture(device: MTLDevice, drawableSize: vector_uint2) -> MTLTexture {
        let descriptor = MTLTextureDescriptor()
        
        descriptor.storageMode = .private
        descriptor.usage = MTLTextureUsage(
            rawValue: MTLTextureUsage.shaderWrite.rawValue | MTLTextureUsage.shaderRead.rawValue
        )
        descriptor.width = Int(drawableSize.x)
        descriptor.height = Int(drawableSize.y)
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            fatalError("can't make texture")
        }
        
        return texture
    }
    
    func draw() {
        
        let textureThreadCount = states.simulateBoids.threadCount(textureSize: MTLSize(width: Int(viewPortSize.x), height: Int(viewPortSize.y), depth: 0))
        let particleThreadCount = states.simulateBoids.threadCount(arrayCount: viewModel.count)
        
        obstacles = viewModel.touches.values.map {
            return Obstacle(
                position: SIMD2<Float>(
                    Float($0.x * UIScreen.main.scale),
                    Float($0.y * UIScreen.main.scale)
                )
            )
        }
        
        if pathTextures.count == 0 {
            pathTextures
                .append(
                    makeTexture(device: metalDevice, drawableSize: viewPortSize)
                )
            pathTextures
                .append(
                    makeTexture(device: metalDevice, drawableSize: viewPortSize)
                )
        }
                
        initializeConfigBufferIfNeeded()
        initializeBoidsIfNeeded()
        
        configBuffer
            .contents()
            .copyMemory(
                from: [
                    viewModel.redConfig,
                    viewModel.greenConfig,
                    viewModel.blueConfig
                ],
                byteCount: 3 * MemoryLayout<BoidsConfig>.size
            )
        
        blurBuffer.contents().copyMemory(from: &viewModel.blurConfig, byteCount: MemoryLayout<BlurConfig>.size)
        
        if let commandBuffer = metalCommandQueue.makeCommandBuffer(),
           let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
            
            // first pass - Boid updates
            if let particleBuffer = particleBuffer {
                
                commandEncoder.setComputePipelineState(states.simulateBoids)
                commandEncoder
                    .setBuffer(
                        particleBuffer,
                        offset: 0,
                        index: Int(BoidsInputIndexParticle.rawValue)
                    )
                commandEncoder
                    .setBytes(
                        &viewModel.count,
                        length: MemoryLayout<Int>.stride,
                        index: Int(BoidsInputIndexParticleCount.rawValue)
                    )
                commandEncoder
                    .setBytes(
                        &viewPortSize.x,
                        length: MemoryLayout<UInt>.stride,
                        index: Int(BoidsInputIndexWidth.rawValue)
                    )
                commandEncoder
                    .setBytes(
                        &viewPortSize.y,
                        length: MemoryLayout<UInt>.stride,
                        index: Int(BoidsInputIndexHeight.rawValue)
                    )
                commandEncoder
                    .setBuffer(
                        obstacleBuffer(),
                        offset: 0,
                        index: Int(BoidsInputIndexObstacle.rawValue)
                    )
                commandEncoder
                    .setBuffer(
                        blurBuffer,
                        offset: 0,
                        index: Int(BoidsInputIndexBlurConfig.rawValue)
                    )
                commandEncoder.setBuffer(configBuffer, offset: 0, index: Int(BoidsInputIndexConfig.rawValue))
                var count = obstacles.count
                commandEncoder
                    .setBytes(
                        &count,
                        length: MemoryLayout<Int>.stride,
                        index: Int(BoidsInputIndexObstacleCount.rawValue)
                    )
                
                commandEncoder
                    .dispatchThreadgroups(
                        particleThreadCount.threadsPerGrid,
                        threadsPerThreadgroup: particleThreadCount.threadsPerGroup
                    )
                commandEncoder
                    .setTexture(
                        pathTextures[0],
                        index: Int(InputTextureIndexPathInput.rawValue)
                    )
                commandEncoder
                    .setTexture(
                        pathTextures[1],
                        index: Int(InputTextureIndexPathOutput.rawValue)
                    )
                
            }
            
            if let drawable = view.currentDrawable {
                
                // second pass - set texture to solid colour
                
                commandEncoder.setComputePipelineState(states.clearTexture)
                commandEncoder.setTexture(drawable.texture, index: Int(InputTextureIndexDrawable.rawValue))
                commandEncoder
                    .dispatchThreadgroups(
                        textureThreadCount.threadsPerGrid,
                        threadsPerThreadgroup: textureThreadCount.threadsPerGroup
                    )
                
                // third pass - draw boids
                
                if particleBuffer != nil /*&& !viewModel.drawTriangles*/ {
                    commandEncoder.setComputePipelineState(states.drawBoids)
                    commandEncoder
                        .setBuffer(
                            particleBuffer,
                            offset: 0,
                            index: Int(
                                ThirdPassInputTextureIndexParticle.rawValue
                            )
                        )
                    commandEncoder
                        .setBytes(
                            &viewModel.drawSize,
                            length: MemoryLayout<Int>.stride,
                            index: Int(
                                ThirdPassInputTextureIndexRadius.rawValue
                            )
                        )
                    commandEncoder
                        .dispatchThreadgroups(
                            particleThreadCount.threadsPerGrid,
                            threadsPerThreadgroup: particleThreadCount.threadsPerGroup
                        )
                    
                    commandEncoder.setComputePipelineState(states.boxBlur)
                    commandEncoder
                        .dispatchThreadgroups(
                            textureThreadCount.threadsPerGrid,
                            threadsPerThreadgroup: textureThreadCount.threadsPerGroup
                        )
                    
                    commandEncoder.setComputePipelineState(states.copyToOutput)
                    commandEncoder
                        .dispatchThreadgroups(
                            textureThreadCount.threadsPerGrid,
                            threadsPerThreadgroup: textureThreadCount.threadsPerGroup
                        )
                }
                
                // finish compute
                
                commandEncoder.endEncoding()
                
//                if viewModel.drawTriangles {
                    let renderPassDescriptor = view.currentRenderPassDescriptor
//                    renderPassDescriptor?.colorAttachments[0].clearColor = MTLClearColorMake(0, 0.5, 0.5, 1.0)
                    renderPassDescriptor?.colorAttachments[0].loadAction = .load
                    renderPassDescriptor?.colorAttachments[0].storeAction = .store
                    
                    let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)!
                    
                    renderEncoder.setRenderPipelineState(states.drawTriangles)
                    
                    renderEncoder.setVertexBuffer(triangleMesh, offset: 0, index: 0)
                    renderEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 1)
                    renderEncoder.setVertexBytes(&viewPortSize, length: MemoryLayout<vector_float2>.size, index: 2)
//                    renderEncoder.setVertexBytes(
//                        &viewModel.config,
//                        length: MemoryLayout<BoidsConfig>.stride,
//                        index: 3
//                    )
                    renderEncoder.setVertexBuffer(configBuffer, offset: 0, index: 3)

                    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: particles.count)
                    
                    renderEncoder.endEncoding()
//                }
                
                commandBuffer.present(drawable)
                
            } else {
                fatalError("No drawable")
            }
            commandBuffer.addCompletedHandler { buffer in
                self.pathTextures.reverse()
            }
            commandBuffer.commit()
        }
        extractParticles()
    }
}

private struct BoidsPipelineStates {
    var clearTexture: MTLComputePipelineState
    var simulateBoids: MTLComputePipelineState
    var drawBoids: MTLComputePipelineState
    var boxBlur: MTLComputePipelineState
    var copyToOutput: MTLComputePipelineState
    var drawTriangles: MTLRenderPipelineState
    
    init(library: MTLLibrary, device: MTLDevice) {
        guard let clearTextureFunction = library.makeFunction(name: "clearTexture"),
              let simulateBoidsFunction = library.makeFunction(name: "simulateBoids"),
              let drawBoidsFunction = library.makeFunction(name: "drawBoids"),
              let boxBlurFunction = library.makeFunction(name: "boxBlurBoids"),
              let copyToOutputFunction = library.makeFunction(name: "copyToOutput") else {
            fatalError("Can't create library functions")
        }
        
        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexFunction = library.makeFunction(name: "vertexMain")
        renderDescriptor.fragmentFunction = library.makeFunction(name: "fragmentMain")
        renderDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            clearTexture = try device.makeComputePipelineState(function: clearTextureFunction)
            simulateBoids = try device.makeComputePipelineState(function: simulateBoidsFunction)
            drawBoids = try device.makeComputePipelineState(function: drawBoidsFunction)
            boxBlur = try device.makeComputePipelineState(function: boxBlurFunction)
            copyToOutput = try device.makeComputePipelineState(function: copyToOutputFunction)
            
            drawTriangles = try device.makeRenderPipelineState(descriptor: renderDescriptor)

        } catch {
            fatalError("failed to make compute pipeline state")
        }
    }
}

private extension MTLComputePipelineState {
    func threadCount(textureSize: MTLSize) -> (threadsPerGroup: MTLSize, threadsPerGrid: MTLSize) {
        let w = self.threadExecutionWidth
        let h = self.maxTotalThreadsPerThreadgroup / w
        let textureThreadsPerGroup = MTLSizeMake(w, h, 1)
        let textureThreadgroupsPerGrid = MTLSize(
            width: (textureSize.width + w - 1) / w,
            height: (textureSize.height + h - 1) / h,
            depth: 1
        )
        
        return (textureThreadsPerGroup, textureThreadgroupsPerGrid)
    }
    
    func threadCount(arrayCount: Int) -> (threadsPerGroup: MTLSize, threadsPerGrid: MTLSize) {
        let threadgroupSizeMultiplier = 1
        let maxThreads = 512
        let particleThreadsPerGroup = MTLSize(
            width: maxThreads,
            height: 1,
            depth: 1
        )
        let particleThreadGroupsPerGrid = MTLSize(
            width: (
                max(
                    arrayCount / (maxThreads * threadgroupSizeMultiplier),
                    1
                )
            ),
            height: 1,
            depth:1
        )
        return (particleThreadsPerGroup, particleThreadGroupsPerGrid)

    }
}


#Preview {
    let viewModel = BoidsViewModel()
    ZStack {
        BoidsView(viewModel: viewModel) //.frame(width: 500, height: 250)
        TapView { touch, optLocation in
            viewModel.updateTouch(touch, location: optLocation)
        }
    }
}
