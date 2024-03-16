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
                Spacer()
                HStack {
                    VStack {
                        Text("offsetX: \(viewModel.config.offsetX)")
                        Slider(value: $viewModel.config.offsetX)
                    }
                    VStack {
                        Text("offsetY: \(viewModel.config.offsetY)")
                        Slider(value: $viewModel.config.offsetY)
                    }
                    
                    VStack {
                        Text("scaleX: \(viewModel.config.scaleX)")
                        Slider(value: $viewModel.config.scaleX, in: 0...400)
                    }
                    
                    VStack {
                        Text("scaleY: \(viewModel.config.scaleY)")
                        Slider(value: $viewModel.config.scaleY, in: 0...400)
                    }
                    VStack {
                        Text("offsetY: \(viewModel.config.offsetY)")
                        Slider(value: $viewModel.config.offsetY)
                    }
                    
                    VStack {
                        Text("size: \(viewModel.config.size)")
                        Slider(value: $viewModel.config.size)
                    }
                }.padding()
            }
        }
    }
}

#Preview {
    HexagonWorkshop()
        .edgesIgnoringSafeArea(.all)
        .statusBar(hidden: true)
}
