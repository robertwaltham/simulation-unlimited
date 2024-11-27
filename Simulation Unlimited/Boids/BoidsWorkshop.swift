//
//  BoidsWorkshop.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-11-15.
//

import SwiftUI

public struct BoidsWorkshop: View {
    @State var viewModel = BoidsViewModel()
    
    public var body: some View {
 
        
        ZStack {
            BoidsView(viewModel: viewModel)
            TapView { touch, optLocation in
                viewModel.updateTouch(touch, location: optLocation)
            }
            VStack {
                HStack {
                    VStack {
                        Text("Max Speed")
                        Slider(value: $viewModel.redConfig.max_speed, in: 0.1...20.0).tint(.red)
                        Slider(value: $viewModel.greenConfig.max_speed, in: 0.1...20.0).tint(.green)
                        Slider(value: $viewModel.blueConfig.max_speed, in: 0.1...20.0).tint(.blue)
                    }
                    VStack {
                        Text("Min Speed")
                        Slider(value: $viewModel.redConfig.min_speed, in: 0.1...10.0).tint(.red)
                        Slider(value: $viewModel.greenConfig.min_speed, in: 0.1...10.0).tint(.green)
                        Slider(value: $viewModel.blueConfig.min_speed, in: 0.1...10.0).tint(.blue)
                    }
                    VStack {
                        Text("Radius")
                        Slider(value: $viewModel.redConfig.radius, in: 0.0...100.0).tint(.red)
                        Slider(value: $viewModel.greenConfig.radius, in: 0.0...100.0).tint(.green)
                        Slider(value: $viewModel.blueConfig.radius, in: 0.0...100.0).tint(.blue)

                    }
                    
                    VStack {
                        Text("Variance").foregroundStyle(Color.blue)
                        Slider(value: $viewModel.redConfig.variance, in: 0.0...10.0).tint(.red)
                        Slider(value: $viewModel.greenConfig.variance, in: 0.0...10.0).tint(.green)
                        Slider(value: $viewModel.blueConfig.variance, in: 0.0...10.0).tint(.blue)
                    }
//                    VStack {
//                        Text("Margin")
//                        Slider(value: $viewModel.redConfig.margin, in: 0.0...200.0).tint(.red)
//                        Slider(value: $viewModel.greenConfig.margin, in: 0.0...200.0).tint(.green)
//                        Slider(value: $viewModel.blueConfig.margin, in: 0.0...200.0).tint(.blue)
//
//                    }

//                    VStack {
//                        Text("Size")
//                        Slider(value: $viewModel.redConfig.draw_scale, in: 0.1...4.0).tint(.red)
//                    }
                }
                    .foregroundStyle(Color.blue)
                    .padding()
                Spacer()
                HStack {
                    VStack {
                        Text("Align").foregroundStyle(Color.blue)
                        Slider(value: $viewModel.redConfig.align_coefficient, in: 0.0...2.0).tint(.red)
                        Slider(value: $viewModel.greenConfig.align_coefficient, in: 0.0...2.0).tint(.green)
                        Slider(value: $viewModel.blueConfig.align_coefficient, in: 0.0...2.0).tint(.blue)
                    }
                    VStack {
                        Text("Separate").foregroundStyle(Color.blue)
                        Slider(value: $viewModel.redConfig.separate_coefficient, in: 0.0...2.0).tint(.red)
                        Slider(value: $viewModel.greenConfig.separate_coefficient, in: 0.0...2.0).tint(.green)
                        Slider(value: $viewModel.blueConfig.separate_coefficient, in: 0.0...2.0).tint(.blue)
                    }
                    VStack {
                        Text("Cohere").foregroundStyle(Color.blue)
                        Slider(value: $viewModel.redConfig.cohere_coefficient, in: 0.0...2.0).tint(.red)
                        Slider(value: $viewModel.greenConfig.cohere_coefficient, in: 0.0...2.0).tint(.green)
                        Slider(value: $viewModel.blueConfig.cohere_coefficient, in: 0.0...2.0).tint(.blue)
                    }
                    
                    VStack {
                        Text("Ignore Others")
                        Toggle("", isOn: $viewModel.redConfig.ignoreOthers).tint(.red)
                        Toggle("", isOn: $viewModel.greenConfig.ignoreOthers).tint(.green)
                        Toggle("", isOn: $viewModel.blueConfig.ignoreOthers).tint(.blue)

                    }
                    
                    VStack {
                        Text("Ignore Self")
                        Toggle("", isOn: $viewModel.redConfig.ignoreSelf).tint(.red)
                        Toggle("", isOn: $viewModel.greenConfig.ignoreSelf).tint(.green)
                        Toggle("", isOn: $viewModel.blueConfig.ignoreSelf).tint(.blue)

                    }
//                    VStack {
//                        Toggle("Draw Mode", isOn: $viewModel.drawTriangles)
//
//                    }
                }
                .foregroundStyle(Color.blue)
                .padding()
            }
 
        }
    }
    
}

#Preview {
    BoidsWorkshop()
}
