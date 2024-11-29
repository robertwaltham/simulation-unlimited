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
        
        var view: MTKView! // TODO: view with touches
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        
        var clearTexture: MTLComputePipelineState!
        var simulateBoids: MTLComputePipelineState!
        var drawBoids: MTLComputePipelineState!
        var drawTriangles: MTLRenderPipelineState!
        
        var viewPortSize: vector_uint2 = vector_uint2(x: 0, y: 0)
        var viewModel: SandViewModel
        
        private var states: [MTLComputePipelineState] = []

                
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
        
        states = try [
            "firstPassSand",
        ]
            .map {
                guard let function = library.makeFunction(name: $0) else {
                    fatalError("Can't make function \($0)")
                }
                return try device.makeComputePipelineState(function: function)
            }
    }
    
    func draw() {
        
        let w = states[0].threadExecutionWidth
        let h = states[0].maxTotalThreadsPerThreadgroup / w
        let textureThreadsPerGroup = MTLSizeMake(w, h, 1)
        let textureThreadgroupsPerGrid = MTLSize(
            width: (Int(viewPortSize.x) + w - 1) / w,
            height: (Int(viewPortSize.y) + h - 1) / h,
            depth: 1
        )
        
        if let commandBuffer = metalCommandQueue.makeCommandBuffer(),
           let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
            
            
            if let drawable = view?.currentDrawable {
                // Draw Background Colour
                commandEncoder.setComputePipelineState(states[0])
                commandEncoder
                    .setTexture(
                        drawable.texture,
                        index: 0
                    )
                commandEncoder
                    .dispatchThreadgroups(
                        textureThreadgroupsPerGrid,
                        threadsPerThreadgroup: textureThreadsPerGroup
                    )
                
                
                commandEncoder.endEncoding()
                commandBuffer.present(drawable)
            }
            
            commandBuffer.commit()
        }
        
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


