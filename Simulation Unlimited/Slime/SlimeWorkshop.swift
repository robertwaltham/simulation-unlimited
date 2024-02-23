////
////  SlimeWorkshop.swift
////  Simulation Unlimited
////
////  Created by Robert Waltham on 2023-09-30.
////
//
//import SwiftUI
//
//struct SlimeWorkshop: View {
//    @State var viewModel = SlimeViewModel()
//    
//    var body: some View {
//        
//        HStack(alignment: .center, spacing: 15) {
//            VStack {
//                Text("Speed: \(viewModel.redConfig.speedMultiplier, specifier: "%.2f")")
//                    .font(.title)
//                Slider(value: $viewModel.redConfig.speedMultiplier, in: 0...viewModel.maxMultiplier)
//            }
//
//            VStack {
//                Text("Falloff: \(viewModel.redConfig.falloff, specifier: "%.3f")")
//                    .font(.title)
//                Slider(value: $viewModel.redConfig.falloff, in: 0...viewModel.maxFalloff)
//            }
//            
//            VStack() {
//                Text("Trail Size: \(Int(viewModel.redConfig.trailRadius))").font(.title)
//                Slider(value: $viewModel.redConfig.trailRadius, in: 1...viewModel.maxRadius)
//            }
//  
//        }.padding(10)
//        
//        SlimeView(viewModel: viewModel)
//        
//        HStack {
//            VStack {
//                Text("Sensor: \(viewModel.redConfig.sensorAngle, specifier: "%.2f")")
//                    .font(.title)
//                Slider(value: $viewModel.redConfig.sensorAngle, in: 0...viewModel.maxSensorAngle)
//            }
//            VStack {
//                Text("Distance: \(viewModel.redConfig.sensorDistance, specifier: "%.2f")")
//                    .font(.title)
//                Slider(value: $viewModel.redConfig.sensorDistance, in: 0...viewModel.maxDistance)
//            }
//            VStack {
//                Text("Turn: \(viewModel.redConfig.turnAngle, specifier: "%.2f")")
//                    .font(.title)
//                Slider(value: $viewModel.redConfig.turnAngle, in: 0...viewModel.maxTurnAngle)
//            }
//            VStack {
//                Text("Start").font(.title)
//                Picker("Start", selection: $viewModel.startType) {
//                    ForEach(StartType.allCases) { type in
//                        type.label.tag(type)
//                    }
//                }
//                .onChange(of: viewModel.startType, {
//                    viewModel.resetOnNext = true
//                })
//            }
//        }
//        .padding(10)
//    }
//}
//
//#Preview {
//    SlimeWorkshop()
//}
