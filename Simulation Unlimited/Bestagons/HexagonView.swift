//
//  HexagonView.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-03-16.
//

import Foundation
import MetalKit
import SwiftUI
import simd

struct HexagonView: UIViewRepresentable {
    typealias UIViewType = MTKView
    
    @State var viewModel: HexagonViewModel
    
    init(viewModel: HexagonViewModel) {
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
        private var metalDevice: MTLDevice!
        private var metalCommandQueue: MTLCommandQueue!
        var viewModel: HexagonViewModel!
        
        private var pathTextures: [MTLTexture] = []
        private var states: [MTLComputePipelineState] = []
//        private var particleBuffer: MTLBuffer!
//        private var configBuffer: MTLBuffer!
        private var viewPortSize = vector_uint2(x: 0, y: 0)
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            viewPortSize = vector_uint2(x: UInt32(size.width), y: UInt32(size.height))
        }
        
        func draw(in view: MTKView) {
            
//            guard !skipDraw else {
//                return
//            }
//
            self.view = view
            
            draw()
        }
        
        init(_ parent: HexagonView) {
            
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            
            super.init()
            

            buildPipeline()
        }
        
    }

}

extension HexagonView.Coordinator {
    
    func draw() {
        
//        let threadgroupSizeMultiplier = 1
//        let maxThreads = 512
        
        let w = states[0].threadExecutionWidth
        let h = states[0].maxTotalThreadsPerThreadgroup / w
        let textureThreadsPerGroup = MTLSizeMake(w, h, 1)
        let textureThreadgroupsPerGrid = MTLSize(width: (Int(viewPortSize.x) + w - 1) / w, height: (Int(viewPortSize.y) + h - 1) / h, depth: 1)
        
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            fatalError("can't make command buffer or encoder")
        }
        
        if let drawable = view?.currentDrawable {
            // Draw Background Colour
            commandEncoder.setComputePipelineState(states[0])
            commandEncoder.setTexture(drawable.texture, index: Int(InputTextureIndexPathHexagon.rawValue))
            commandEncoder.setBytes(&viewModel.config, length: MemoryLayout<HexagonConfig>.stride, index: 7)
            commandEncoder.dispatchThreadgroups(textureThreadgroupsPerGrid, threadsPerThreadgroup: textureThreadsPerGroup)
            
            commandEncoder.endEncoding()
            commandBuffer.present(drawable)
            
        }
        
        commandBuffer.commit()
        
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
        
        states = try ["hexagonPass"].map {
            guard let function = library.makeFunction(name: $0) else {
                fatalError("Can't make function \($0)")
            }
            return try device.makeComputePipelineState(function: function)
        }
    }
}


#Preview {
    HexagonView(viewModel: HexagonViewModel())
        .edgesIgnoringSafeArea(.all)
        .statusBar(hidden: true)
}
