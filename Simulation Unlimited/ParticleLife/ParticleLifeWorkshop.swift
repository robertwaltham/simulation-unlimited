//
//  ParticleLifeWorkshop.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2023-10-11.
//

import SwiftUI

struct ParticleLifeWorkshop: View {
    @State var viewModel = ParticleLifeViewModel(count: 8192)
    @State var showWeights = false
    @State var showParams = false
    @State var stepper: Float = 0.5
    
    var body: some View {
        
        ZStack {
            
            ParticleLifeView(viewModel: viewModel).frame(maxHeight: .infinity)
            TapView { touch, optLocation in
                viewModel.updateTouch(touch, location: optLocation)
            }
            
            VStack {
                HStack {
                    Spacer()
                    fpsCounter()
                }
                Spacer()
            }
            .padding()
            
            VStack {
                Spacer()
                HStack {
                    Button {
                        showWeights = true
                    } label: {
                        Label("Weights", systemImage: "figure.walk.circle.fill")
                            .frame(minWidth: 130, minHeight: 52)
                            .contentShape(Rectangle())
                    }
                    .controlSize(.large)
                    .popover(isPresented: $showWeights, attachmentAnchor: .point(.top), arrowEdge: .bottom) {
                        weightWidget()
                    }
                    .padding()
                    
                    Button {
                        viewModel.resetOnNext = true
                    } label: {
                        Label("Reset Particles", systemImage: "arrow.counterclockwise.circle.fill")
                            .frame(minWidth: 190, minHeight: 52)
                            .contentShape(Rectangle())
                    }
                    .controlSize(.large)
                    .padding()
                    
                    Button {
                        showParams = true
                    } label: {
                        Label("Parameters", systemImage: "figure.walk.circle.fill")
                            .frame(minWidth: 150, minHeight: 52)
                            .contentShape(Rectangle())
                    }
                    .controlSize(.large)
                    .popover(isPresented: $showParams, attachmentAnchor: .point(.top), arrowEdge: .bottom) {
                        paramWidget()
                    }
                    .padding()
                }
                
            }.foregroundStyle(Color.blue)
        }
    }
    
    @ViewBuilder
    private func fpsCounter() -> some View {
        Text("\(viewModel.fpsCounter.fps, specifier: "%.0f") FPS")
            .font(.caption.monospacedDigit().weight(.semibold))
            .foregroundStyle(Color.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.65), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.blue.opacity(0.8), lineWidth: 1)
            )
            .allowsHitTesting(false)
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
    private func paramWidget() -> some View {
        VStack {
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
                
            }
            
            HStack(alignment: .center, spacing: 15) {
                HStack {
                    Text("R Min: \(viewModel.config.rMinDistance, specifier: "%.2f")")
                        .font(.title3)
                    Slider(value: $viewModel.config.rMinDistance, in: 0...viewModel.maxMinDistance)
                }
                
                HStack {
                    Text("R MAx: \(viewModel.config.rMaxDistance, specifier: "%.1f")")
                        .font(.title3)
                    Slider(value: $viewModel.config.rMaxDistance, in: 1...viewModel.maxMaxDistance)
                }
                
                HStack() {
                    Text("S Max: \(viewModel.config.maxSpeed, specifier: "%.1f")").font(.title3)
                    Slider(value: $viewModel.config.maxSpeed, in: 0...viewModel.maxParticleSpeed)
                }
            }
        }
        .padding()
        .frame(minWidth: 800)
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
                
                ForEach(0...Int(viewModel.config.flavourCount), id: \.self) { j in
                    
                    if j == 0 {
                        GridRow {
                            ForEach(0...Int(viewModel.config.flavourCount), id: \.self) { i in
                                if i > 0 {
                                    rectangle(color: colors[i-1])
                                } else {
                                    rectangle(color: Color.white)
                                }
                            }
                        }
                    } else {
                        GridRow {
                            ForEach(0...Int(viewModel.config.flavourCount), id: \.self) { i in
                                if i == 0 {
                                    rectangle(color: colors[j-1])
                                } else {
                                    
                                    let binding = Binding<Float> {
                                        viewModel.weight(x: j-1, y: i-1)
                                    } set: { newValue in
                                        viewModel.setWeight(x: j-1, y: i-1, value: newValue)
                                    }
                                    
                                    Picker("Weight", selection: binding) {
                                        ForEach(ParticleLifeViewModel.weightOptions, id: \.self) { i in
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
