//
//  BoidsView.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2023-09-29.
//

import SwiftUI

import Foundation
import MetalKit
import SwiftUI

struct BoidsView: UIViewRepresentable {
    
    typealias UIViewType = MTKView
    
    var drawSize: Float
    var count: Int
    
    init() {
        self.drawSize = 2
        self.count = 4096
    }
    
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
        let boidsRenderer = context.coordinator
        
        boidsRenderer.drawRadius = Int(drawSize)
        boidsRenderer.particleCount = count
    }
    
    func makeCoordinator() -> Coordinator {
        BoidsView.Coordinator(self)
    }
    
    class Coordinator : NSObject, MTKViewDelegate {
        
        var view: MTKView! // TODO: view with touches
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        
        var firstState: MTLComputePipelineState!
        var secondState: MTLComputePipelineState!
        var thirdState: MTLComputePipelineState!
        
        var particleBuffer: MTLBuffer!
        
        var particleCount = 0
        
        
        var drawRadius: Int = 4
        
        var viewPortSize: vector_uint2 = vector_uint2(x: 0, y: 0)
        
        var particles = [Particle]()
        var obstacles = [Obstacle]()
        
        var config = BoidsConfig(max_speed: 5, margin: 50, align_coefficient: 0.3, cohere_coefficient: 0.4, separate_coefficient: 0.5, radius: 15)
        
        init(_ parent: BoidsView) {
            
            
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
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
    
    var description: String {
        return "p<\(position.x),\(position.y)> v<\(velocity.x),\(velocity.y)> a<\(acceleration.x),\(acceleration.y) f<\(force.x),\(force.y)>"
    }
}

struct Obstacle {
    var position: SIMD2<Float>
}

struct BoidsConfig {
    var max_speed: Float
    var margin: Float
    var align_coefficient: Float
    var cohere_coefficient: Float
    var separate_coefficient: Float
    var radius: Float
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
        let maxSpeed = config.max_speed
        
        for _ in 0 ..< particleCount {
            let speed = SIMD2<Float>(Float.random(in: -maxSpeed...maxSpeed), Float.random(in: -maxSpeed...maxSpeed))
            let position = SIMD2<Float>(randomPosition(length: UInt(viewPortSize.x)), randomPosition(length: UInt(viewPortSize.y)))
            let particle = Particle(position: position,
                                    velocity: speed)
            particles.append(particle)
        }
        let size = particles.count * MemoryLayout<Particle>.size
        particleBuffer = metalDevice.makeBuffer(bytes: &particles, length: size, options: [])
        
    }
    
    private func randomPosition(length: UInt) -> Float {
        let maxSize = length - (UInt(config.margin) * 2)
        return Float(arc4random_uniform(UInt32(maxSize)) + UInt32(config.margin))
    }
    
    func buildPipeline() {
        
        // make Command queue
        guard let queue = metalDevice.makeCommandQueue() else {
            fatalError("can't make queue")
        }
        metalCommandQueue = queue
        
        
        // pipeline state
        do {
            try buildRenderPipelineWithDevice(device: metalDevice, metalKitView: view)
        } catch {
            fatalError("Unable to compile render pipeline state.  Error info: \(error)")
        }
        
    }
    
    func buildRenderPipelineWithDevice(device: MTLDevice, metalKitView: MTKView) throws {
        /// Build a render state pipeline object
        
        guard let library = device.makeDefaultLibrary() else {
            fatalError("can't create libray")
        }
        
        guard let firstPass = library.makeFunction(name: "firstPass") else {
            fatalError("can't create first pass")
        }
        firstState = try device.makeComputePipelineState(function: firstPass)
        
        guard let secondPass = library.makeFunction(name: "secondPass") else {
            fatalError("can't create first pass")
        }
        secondState = try device.makeComputePipelineState(function: secondPass)
        
        guard let thirdPass = library.makeFunction(name: "thirdPass") else {
            fatalError("can't create first pass")
        }
        thirdState = try device.makeComputePipelineState(function: thirdPass)
        
    }
    
    func extractParticles() {
        
        guard particleBuffer != nil else {
            return
        }
        
        particles = []
        for i in 0..<particleCount {
            particles.append((particleBuffer.contents() + (i * MemoryLayout<Particle>.size)).load(as: Particle.self))
        }
    }
    
    // MARK: - UIViewRepresentable.Coordinator
    
    func drawableSizeWillChange(_ size: CGSize) {
        /// Respond to drawable size or orientation changes here
        viewPortSize = vector_uint2(x: UInt32(size.width), y: UInt32(size.height))
    }
    
    func draw() {
        
        let threadgroupSizeMultiplier = 1
        let maxThreads = 512
        let particleThreadsPerGroup = MTLSize(width: maxThreads, height: 1, depth: 1)
        let particleThreadGroupsPerGrid = MTLSize(width: (max(particleCount / (maxThreads * threadgroupSizeMultiplier), 1)), height: 1, depth:1)
        
        let w = firstState.threadExecutionWidth
        let h = firstState.maxTotalThreadsPerThreadgroup / w
        let textureThreadsPerGroup = MTLSizeMake(w, h, 1)
        let textureThreadgroupsPerGrid = MTLSize(width: (Int(viewPortSize.x) + w - 1) / w, height: (Int(viewPortSize.y) + h - 1) / h, depth: 1)
        
        initializeBoidsIfNeeded()
        
        if let commandBuffer = metalCommandQueue.makeCommandBuffer(),
           let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
            
            // first pass - Boid updates
            if let particleBuffer = particleBuffer {
                
                commandEncoder.setComputePipelineState(secondState)
                commandEncoder.setBuffer(particleBuffer, offset: 0, index: Int(BoidsInputIndexParticle.rawValue))
                commandEncoder.setBytes(&particleCount, length: MemoryLayout<Int>.stride, index: Int(BoidsInputIndexParticleCount.rawValue))
                commandEncoder.setBytes(&viewPortSize.x, length: MemoryLayout<UInt>.stride, index: Int(BoidsInputIndexWidth.rawValue))
                commandEncoder.setBytes(&viewPortSize.y, length: MemoryLayout<UInt>.stride, index: Int(BoidsInputIndexHeight.rawValue))
                commandEncoder.setBuffer(obstacleBuffer(), offset: 0, index: Int(BoidsInputIndexObstacle.rawValue))
                commandEncoder.setBytes(&config, length: MemoryLayout<BoidsConfig>.stride, index: Int(BoidsInputIndexConfig.rawValue))
                var count = obstacles.count
                commandEncoder.setBytes(&count, length: MemoryLayout<Int>.stride, index: Int(BoidsInputIndexObstacleCount.rawValue))
                
                commandEncoder.dispatchThreadgroups(particleThreadGroupsPerGrid, threadsPerThreadgroup: particleThreadsPerGroup)
                
            }
            
            if let drawable = view.currentDrawable {
                
                // second pass - set texture to solid colour
                
                commandEncoder.setComputePipelineState(firstState)
                commandEncoder.setTexture(drawable.texture, index: 0)
                commandEncoder.dispatchThreadgroups(textureThreadgroupsPerGrid, threadsPerThreadgroup: textureThreadsPerGroup)
                
                // third pass - draw boids
                
                if let particleBuffer = particleBuffer {
                    commandEncoder.setComputePipelineState(thirdState)
                    commandEncoder.setTexture(drawable.texture, index: 0)
                    commandEncoder.setBuffer(particleBuffer, offset: 0, index: Int(ThirdPassInputTextureIndexParticle.rawValue))
                    commandEncoder.setBytes(&drawRadius, length: MemoryLayout<Int>.stride, index: Int(ThirdPassInputTextureIndexRadius.rawValue))
                    commandEncoder.dispatchThreadgroups(particleThreadGroupsPerGrid, threadsPerThreadgroup: particleThreadsPerGroup)
                }
                
                // finish
                
                commandEncoder.endEncoding()
                commandBuffer.present(drawable)
                
            } else {
                fatalError("No drawable")
            }
            
            commandBuffer.commit()
        }
        extractParticles()
    }
    
    //MARK: - Touches
    
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        obstacles = touches.map {
            let loc = $0.location(in: $0.view)
            let scale = Float($0.view?.contentScaleFactor ?? 1)
            return Obstacle(position: SIMD2<Float>(Float(loc.x) * scale, Float(loc.y) * scale))
        }
    }
    
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        obstacles = touches.map {
            let loc = $0.location(in: $0.view)
            let scale = Float($0.view?.contentScaleFactor ?? 1)
            return Obstacle(position: SIMD2<Float>(Float(loc.x) * scale, Float(loc.y) * scale))
        }
    }
    
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        obstacles.removeAll()
    }
    
    func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        obstacles.removeAll()
    }
}


#Preview {
    BoidsView()
}
