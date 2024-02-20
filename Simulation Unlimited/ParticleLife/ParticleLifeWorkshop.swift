//
//  ParticleLifeWorkshop.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2023-10-11.
//

import SwiftUI

struct ParticleLifeWorkshop: View {
    @State var viewModel = ParticleLifeViewModel()
    @State var showWeights = false
    @State var stepper: Float = 0.5
    
    var body: some View {
        
        HStack(alignment: .center, spacing: 15) {
            HStack {
                Text("Speed: \(viewModel.config.speedMultiplier, specifier: "%.2f")")
                    .font(.title3)
                Slider(value: $viewModel.config.speedMultiplier, in: 0...viewModel.maxMultiplier)
            }
            
            HStack {
                Text("Falloff: \(viewModel.config.falloff, specifier: "%.3f")")
                    .font(.title3)
                Slider(value: $viewModel.config.falloff, in: 0...viewModel.maxFalloff)
            }
            
            HStack() {
                Text("Trail Size: \(Int(viewModel.config.trailRadius))").font(.title3)
                Slider(value: $viewModel.config.trailRadius, in: 1...viewModel.maxRadius)
            }
            
//            HStack() {
//                Toggle("Particles", isOn: $viewModel.drawParticles)
//                Toggle("Path", isOn: $viewModel.drawPath)
//            }
            
        }
        
        HStack(alignment: .center, spacing: 15) {
            HStack {
                Text("R Min: \(viewModel.config.rMinDistance, specifier: "%.2f")")
                    .font(.title3)
                Slider(value: $viewModel.config.rMinDistance, in: 0...10)
            }
            
            HStack {
                Text("R MAx: \(viewModel.config.rMaxDistance, specifier: "%.1f")")
                    .font(.title3)
                Slider(value: $viewModel.config.rMaxDistance, in: 1...50)
            }
            
            HStack() {
                Text("S Max: \(viewModel.config.maxSpeed, specifier: "%.1f")").font(.title3)
                Slider(value: $viewModel.config.maxSpeed, in: 0...5)
            }
        }
        
        ParticleLifeView(viewModel: viewModel)
        
        HStack {
//            ForEach(viewModel.getSwiftUIColors(), id: \.self) { c in
//                rectangle(color: c)
//            }
//            HStack(alignment: .center, spacing: 15) {
//                HStack {
//                    Text("Draw Radius: \(viewModel.config.drawRadius, specifier: "%.f")")
//                        .font(.title3)
//                    Slider(value: $viewModel.config.drawRadius, in: 1...10)
//                }
//
//                HStack {
//                    Text("Trail Radius: \(viewModel.config.trailRadius, specifier: "%.f")")
//                        .font(.title3)
//                    Slider(value: $viewModel.config.trailRadius, in: 1...10)
//                }
//            }
            
            
            
            HStack {
                Button {
                    showWeights = true
                } label: {
                    Label("Weights", systemImage: "figure.walk.circle.fill")
                }.popover(isPresented: $showWeights) {
                    weightWidget()
                }.padding()
                
                Button {
                    viewModel.resetOnNext = true
                } label: {
                    Label("Reset Particles", systemImage: "arrow.counterclockwise.circle.fill")
                }.padding()
            }
            



        }
    }
    
    @ViewBuilder
    private func rectangle(color: Color) -> some View {
        RoundedRectangle(cornerSize: CGSize(width: 5, height: 5))
            .foregroundColor(color)
            .padding(1)
            .frame(width: 50, height: 50)
    }
    
    @ViewBuilder
    private func text(weight: Float) -> some View {
        Text(weight, format: .number)
            .foregroundStyle( weight > 0 ? Color.green : Color.gray) // TODO: Scale color
    }
    
    @ViewBuilder
    private func weightWidget() -> some View {
        let colors = viewModel.getSwiftUIColors()
        VStack {
            HStack {
                Button {
                    viewModel.randomizeWeights()
                } label: {
                    Label("Randomize", systemImage: "shuffle.circle.fill")
                }.padding()
                
                Button {
                    viewModel.resetWeights()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise.circle.fill")
                }.padding()
                
                Button {
                    viewModel.invertWeights()
                } label: {
                    Label("Invert", systemImage: "arrow.up.arrow.down.circle.fill")
                }.padding()
                
            }
            Grid {

                ForEach(0...viewModel.config.flavourCount, id: \.self) { j in
                    
                    if j == 0 {
                        GridRow {
                            ForEach(0...viewModel.config.flavourCount, id: \.self) { i in
                                if i > 0 {
                                    rectangle(color: colors[i-1])
                                } else {
                                    rectangle(color: Color.white)
                                }
                            }
                        }
                    } else {
                        GridRow {
                            ForEach(0...viewModel.config.flavourCount, id: \.self) { i in
                                if i == 0 {
                                    rectangle(color: colors[j-1])
                                } else {

                                    let binding = Binding<Float> {
                                        viewModel.weight(x: j-1, y: i-1)
                                    } set: { newValue in
                                        viewModel.setWeight(x: j-1, y: i-1, value: newValue)
                                    }
                                    
                                    let stride: [Float] = stride(from: -1.0, to: 1.5, by: 0.5).compactMap { $0 }
                                    Picker("Weight", selection: binding) {
                                        ForEach(stride, id: \.self) { i in
                                            Text("\(i, specifier: "%.1f")")

                                        }
                                    }
                                    .frame(width: 75)

                                }
                            }
                        }
                    }
                }
            }.padding(5)
        }
        
    }
    
}

#Preview {
    ParticleLifeWorkshop()
}
