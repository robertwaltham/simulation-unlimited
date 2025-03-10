//
//  SandView.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-11-29.
//

import SwiftUI

import Foundation
import MetalKit
import Metal
import SwiftUI

struct SandView: UIViewRepresentable {
    
    typealias UIViewType = MTKView
    
    @State var viewModel = SandViewModel()
    
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
        SandView.Coordinator(self)
    }
    
    class Coordinator : NSObject, MTKViewDelegate {
        
        var view: MTKView!
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        
        var viewPortSize: vector_uint2 = vector_uint2(x: 0, y: 0)
        var viewModel: SandViewModel
        
        fileprivate var states: SandPipelineStates!
                
        init(_ parent: SandView) {
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            self.viewModel = parent.viewModel
            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            viewPortSize = vector_uint2(
                x: UInt32(size.width),
                y: UInt32(size.height)
            )
        }
        
        func draw(in view: MTKView) {
            draw()
        }
    }
}

extension SandView.Coordinator {
    
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
            fatalError(
                "Unable to compile render pipeline state.  Error info: \(error)"
            )
        }
    }
    
    func buildRenderPipelineWithDevice(device: MTLDevice) throws {
        /// Build a render state pipeline object
        
        guard let library = device.makeDefaultLibrary() else {
            fatalError("can't create libray")
        }
        
        states = SandPipelineStates(library: library, device: device)
    }
    
    func draw() {
        
        
        if let commandBuffer = metalCommandQueue.makeCommandBuffer(),
           let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
            
            if let drawable = view?.currentDrawable {
                
                let threadCount = states.firstPass.threadCount(textureSize: MTLSize(width: Int(viewPortSize.x), height: Int(viewPortSize.y), depth: 0))

                // Draw Background Colour
                commandEncoder.setComputePipelineState(states.firstPass)
                commandEncoder
                    .setTexture(
                        drawable.texture,
                        index: 0
                    )
                commandEncoder
                    .dispatchThreadgroups(
                        threadCount.threadsPerGrid,
                        threadsPerThreadgroup: threadCount.threadsPerGroup
                    )
                
                commandEncoder.endEncoding()
                commandBuffer.present(drawable)
            }
            
            commandBuffer.commit()
        }
        
    }
}

private struct SandPipelineStates {
    let firstPass: MTLComputePipelineState
    
    init(library: MTLLibrary, device: MTLDevice) {
        guard let firstPass = library.makeFunction(name: "firstPassSand") else {
            fatalError("Failed to create function")
        }
        
        do {
            self.firstPass = try device.makeComputePipelineState(function: firstPass)

        } catch {
            fatalError("failed to make compute pipeline state")
        }
    }
}

extension MTLComputePipelineState {
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
}

#Preview {
    let viewModel = SandViewModel()
    ZStack {
        SandView(viewModel: viewModel) 
        TapView { touch, optLocation in
            viewModel.updateTouch(touch, location: optLocation)
        }
    }
}
