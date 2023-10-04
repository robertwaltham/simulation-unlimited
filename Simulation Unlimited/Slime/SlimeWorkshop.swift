//
//  SlimeWorkshop.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2023-09-30.
//

import SwiftUI

struct SlimeWorkshop: View {
    @State var viewModel = SlimeViewModel()
    
    var body: some View {
        
        HStack(alignment: .center, spacing: 15) {
            VStack {
                Text("Speed: \(viewModel.config.speedMultiplier, specifier: "%.2f")")
                    .font(.title)
                Slider(value: $viewModel.config.speedMultiplier, in: 0...viewModel.maxMultiplier)
            }

            VStack {
                Text("Falloff: \(viewModel.config.falloff, specifier: "%.3f")")
                    .font(.title)
                Slider(value: $viewModel.config.falloff, in: 0...viewModel.maxFalloff)
            }
            
            VStack() {
                Text("Trail Size: \(Int(viewModel.config.trailRadius))").font(.title)
                Slider(value: $viewModel.config.trailRadius, in: 1...viewModel.maxRadius)
            }
  
        }.padding(10)
        
        SlimeView(viewModel: viewModel)
        
        HStack {
            VStack {
                Text("Sensor: \(viewModel.config.sensorAngle, specifier: "%.2f")")
                    .font(.title)
                Slider(value: $viewModel.config.sensorAngle, in: 0...viewModel.maxSensorAngle)
            }
            VStack {
                Text("Distance: \(viewModel.config.sensorDistance, specifier: "%.2f")")
                    .font(.title)
                Slider(value: $viewModel.config.sensorDistance, in: 0...viewModel.maxDistance)
            }
            VStack {
                Text("Turn: \(viewModel.config.turnAngle, specifier: "%.2f")")
                    .font(.title)
                Slider(value: $viewModel.config.turnAngle, in: 0...viewModel.maxTurnAngle)
            }
        }
        .padding(10)
    }
}

#Preview {
    SlimeWorkshop()
}
