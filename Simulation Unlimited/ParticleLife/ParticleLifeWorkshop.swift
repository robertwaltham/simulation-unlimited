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
                Text("S Max: \(Int(viewModel.config.maxSpeed))").font(.title3)
                Slider(value: $viewModel.config.maxSpeed, in: 1...20)
            }
        }
        
        ParticleLifeView(viewModel: viewModel)
        
        HStack {
            ForEach(viewModel.getSwiftUIColors(), id: \.self) { c in
                rectangle(color: c)
            }
            
            Button {
                showWeights = true
            } label: {
                Label("Weights", systemImage: "figure.walk.circle.fill")
            }.popover(isPresented: $showWeights) {
                let colors = viewModel.getSwiftUIColors()
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
                                        RoundedRectangle(cornerSize: CGSize(width: 5, height: 5))
                                            .stroke(.gray, lineWidth: 1)
                                            .foregroundColor(Color.white)
                                            .padding(1)
                                            .frame(width: 50, height: 50)
                                            .overlay {
                                                text(weight: viewModel.weight(x: j-1, y: i-1))
                                            }
                                    }
                                }
                            }
                        }
                    }
                }.padding(5)
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
    
}

#Preview {
    ParticleLifeWorkshop()
}
