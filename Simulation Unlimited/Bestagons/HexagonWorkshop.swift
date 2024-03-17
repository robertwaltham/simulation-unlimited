//
//  HexagonWorkshop.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-03-16.
//

import SwiftUI

struct HexagonWorkshop: View {
    
    @State var viewModel: HexagonViewModel = HexagonViewModel()

    var body: some View {
        ZStack {
            HexagonView(viewModel: viewModel)
            
            VStack {
                HStack {
                    VStack {
                        Text("modX: \(viewModel.config.modX)")
                        Slider(value: $viewModel.config.modX, in: 0...10.0)
                    }
                    VStack {
                        Text("modY: \(viewModel.config.modY)")
                        Slider(value: $viewModel.config.modY, in: 0...10.0)
                    }
                    
                    VStack {
                        Text("multiplier: \(viewModel.config.multiplier)")
                        Slider(value: $viewModel.config.multiplier, in: 0...30.0)
                    }
                    
                    VStack {
                        Text("color offset: \(viewModel.config.colorOffset)")
                        Slider(value: $viewModel.config.colorOffset, in: 0...90.0)
                    }
                    
                }.padding(EdgeInsets(top: 30, leading: 10, bottom: 10, trailing: 10))
                Spacer()
                HStack {
                    VStack {
                        Text("offsetX: \(viewModel.config.offsetX)")
                        Slider(value: $viewModel.config.offsetX, in: -3.0...3.0)
                    }
                    VStack {
                        Text("offsetY: \(viewModel.config.offsetY)")
                        Slider(value: $viewModel.config.offsetY, in: -3.0...3.0)
                    }
                    
                    VStack {
                        Text("scaleX: \(viewModel.config.shiftX)")
                        Slider(value: $viewModel.config.shiftX, in: 0...400)
                    }
                    
                    VStack {
                        Text("scaleY: \(viewModel.config.shiftY)")
                        Slider(value: $viewModel.config.shiftY, in: 0...400)
                    }
                    VStack {
                        Text("offsetY: \(viewModel.config.offsetY)")
                        Slider(value: $viewModel.config.offsetY)
                    }
                    
                    VStack {
                        Text("size: \(viewModel.config.size)")
                        Slider(value: $viewModel.config.size)
                    }
                }.padding(EdgeInsets(top: 10, leading: 10, bottom: 30, trailing: 10))
            }.foregroundColor(.red)
        }
    }
}

#Preview {
    HexagonWorkshop()
        .edgesIgnoringSafeArea(.all)
        .statusBar(hidden: true)
}
