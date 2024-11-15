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

            VStack {
                HStack {
                    VStack {
                        Text("Speed").foregroundStyle(Color.blue)
                        Slider(value: $viewModel.config.max_speed, in: 0.0...10.0)
                    }
                    VStack {
                        Text("Radius").foregroundStyle(Color.blue)
                        Slider(value: $viewModel.config.radius, in: 0.0...30.0)
                    }
                    VStack {
                        Text("Margin").foregroundStyle(Color.blue)
                        Slider(value: $viewModel.config.margin, in: 0.0...200.0)
                    }
                }.padding()
                Spacer()
                HStack {
                    VStack {
                        Text("Align").foregroundStyle(Color.blue)
                        Slider(value: $viewModel.config.align_coefficient, in: 0.0...1.0)
                    }
                    VStack {
                        Text("Separate").foregroundStyle(Color.blue)
                        Slider(value: $viewModel.config.separate_coefficient, in: 0.0...1.0)
                    }
                    VStack {
                        Text("Cohere").foregroundStyle(Color.blue)
                        Slider(value: $viewModel.config.cohere_coefficient, in: 0.0...1.0)
                    }
                }.padding()
            }
 
        }
    }
    
}

#Preview {
    BoidsWorkshop()
}
