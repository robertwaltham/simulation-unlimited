//
//  ParticleLifeWorkshop.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2023-10-11.
//

import SwiftUI

struct ParticleLifeWorkshop: View {
    @State var viewModel = ParticleLifeViewModel(count: 8192)
    @State var modulationClock = ModulationClock()
    @State var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @State var showWeights = false
    @State var showParams = false
    @State var showGradient = false
    @State var stepper: Float = 0.5
    
    var body: some View {
        
        ZStack {
            
            ParticleLifeView(viewModel: viewModel)
                .frame(maxHeight: .infinity)
                .onReceive(timer) { date in
                    modulationClock.tick(delta: 0.01)
                    viewModel.updateModulation(time: modulationClock.time)
                    viewModel.updateGradientNoiseAnimation(currentDate: date)
                }
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
                        modulationClock.reset()
                        viewModel.updateModulation(time: modulationClock.time)
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
                    
                    Button {
                        showGradient = true
                    } label: {
                        Label("Gradient", systemImage: "circle.hexagongrid.fill")
                            .frame(minWidth: 150, minHeight: 52)
                            .contentShape(Rectangle())
                    }
                    .controlSize(.large)
                    .popover(isPresented: $showGradient, attachmentAnchor: .point(.top), arrowEdge: .bottom) {
                        gradientWidget()
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
            FloatModulationControl(modulation: $viewModel.speedMultiplierModulation, time: modulationClock.time)
            FloatModulationControl(modulation: $viewModel.falloffModulation, time: modulationClock.time)
//            FloatModulationControl(modulation: $viewModel.trailRadiusModulation, time: modulationClock.time)
            FloatModulationControl(modulation: $viewModel.rMinDistanceModulation, time: modulationClock.time)
            FloatModulationControl(modulation: $viewModel.rMaxDistanceModulation, time: modulationClock.time)
            FloatModulationControl(modulation: $viewModel.maxSpeedModulation, time: modulationClock.time)
        }
        .padding(.all, 20)
        .frame(minWidth: 800)
    }
    
    @ViewBuilder
    private func gradientWidget() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Enable Force", isOn: $viewModel.gradientNoiseSettings.isEnabled)
            Toggle("Show Background", isOn: $viewModel.gradientNoiseSettings.isDisplayed)
            Toggle("Animate Noise", isOn: $viewModel.gradientNoiseSettings.animateOverTime)
            
            gradientSlider(
                title: "Max Force",
                value: $viewModel.gradientNoiseSettings.forceMultiplier,
                range: 0...viewModel.maxGradientForce,
                format: "%.3f"
            )
            
            gradientSlider(
                title: "Noise Scale",
                value: $viewModel.gradientNoiseSettings.scale,
                range: 0.25...viewModel.maxGradientNoiseScale,
                format: "%.2f"
            )
            
//            gradientSlider(
//                title: "Z Offset",
//                value: $viewModel.gradientNoiseSettings.zOffset,
//                range: 0...viewModel.maxGradientZOffset,
//                format: "%.2f"
//            )
            
            gradientSlider(
                title: "Animation Speed",
                value: $viewModel.gradientNoiseSettings.animationSpeed,
                range: 0...viewModel.maxGradientAnimationSpeed,
                format: "%.2f"
            )
            
            gradientSlider(
                title: "Persistence",
                value: $viewModel.gradientNoiseSettings.persistence,
                range: 0...viewModel.maxGradientPersistence,
                format: "%.2f"
            )
            
            gradientSlider(
                title: "Lacunarity",
                value: $viewModel.gradientNoiseSettings.lacunarity,
                range: 1...viewModel.maxGradientLacunarity,
                format: "%.2f"
            )
            
            Stepper("Octaves: \(viewModel.gradientNoiseSettings.octaves)", value: $viewModel.gradientNoiseSettings.octaves, in: 1...viewModel.maxGradientOctaves)
            Stepper("Texture: \(viewModel.gradientNoiseSettings.textureSize)", value: $viewModel.gradientNoiseSettings.textureSize, in: 64...viewModel.maxGradientTextureSize, step: 64)
        }
        .padding(.all, 20)
        .frame(minWidth: 420)
    }
    
    @ViewBuilder
    private func gradientSlider(title: String, value: Binding<Float>, range: ClosedRange<Float>, format: String) -> some View {
        HStack {
            Text("\(title): \(String(format: format, value.wrappedValue))")
                .font(.title3)
                .frame(width: 190, alignment: .leading)
            Slider(value: value, in: range)
        }
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
                                    
                                    Stepper(value: binding, in: viewModel.weightRange, step: viewModel.weightStep) {
                                        Text("\(binding.wrappedValue, specifier: "%.1f")")
                                            .monospacedDigit()
                                            .frame(width: 44, alignment: .trailing)
                                    }
                                    .frame(width: 130)
                                    
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
