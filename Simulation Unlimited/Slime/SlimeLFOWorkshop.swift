//
//  SlimeLFOWorkshop.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-02-20.
//

import SwiftUI

struct SlimeLFOWorkshop: View {
    @State var viewModel = SlimeViewModel()
    @State var modulationClock = ModulationClock()
    @State var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    @State private var showLFO = false
    @State private var showSpeed = false
    @State private var showAngle = false
    @State private var showTurn = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            SlimeView(viewModel: viewModel)
                .onReceive(timer, perform: { _ in
                    modulationClock.tick(delta: 0.01)
                    viewModel.time = modulationClock.time
                    viewModel.update()
                    if viewModel.time == 0 {
                        modulationClock.reset()
                    }
                })
            
            VStack {
                Spacer()
                
                HStack {
                    Picker("Start", selection: $viewModel.startType) {
                        ForEach(StartType.allCases) { type in
                            type.label.tag(type)
                        }
                    }
                    
                    Button("Reset") {
                        viewModel.resetOnNext = true
                        modulationClock.reset()
                        viewModel.time = modulationClock.time
                    }
                    
                    Spacer()
                    
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "hexagon")
                    }.popover(isPresented: $showSettings, attachmentAnchor: .point(.top), arrowEdge: .bottom) {
                        VStack {
                            HStack {
                                Text("Blur Radius")
                                Picker(selection: $viewModel.redConfig.config.blurSize, label: Text("Blur")) {
                                    Text("\(1)").tag(Float(1))
                                    Text("\(2)").tag(Float(3))
                                    Text("\(3)").tag(Float(5))
                                    Text("\(4)").tag(Float(7))
                                }
                            }.padding()
                            
                            HStack {
                                Text("Cycle Length: \(viewModel.time, specifier: "%.f")/\(viewModel.cycleLength, specifier: "%.f") ").foregroundStyle(Color.blue)
                                
                                Slider(value: $viewModel.cycleLength, in: SlimeViewModel.minCycleLength...SlimeViewModel.maxCycleLength)
                            }.padding()
                            Text("Hexagons")

                            VStack {
                                LowFrequencyOscillatorControl(oscillator: $viewModel.redConfig.hexagonLFO, name: "Weight \(viewModel.redConfig.config.hexagonWeight.formatted(.percent.precision(.fractionLength(0...0))))", offset: 0...1, time: viewModel.time)
                                    .tint(Color.red)
                                LowFrequencyOscillatorControl(oscillator: $viewModel.greenConfig.hexagonLFO, name: "Weight \(viewModel.greenConfig.config.hexagonWeight.formatted(.percent.precision(.fractionLength(0...0))))", offset: 0...1, time: viewModel.time)
                                    .tint(Color.green)
                                LowFrequencyOscillatorControl(oscillator: $viewModel.blueConfig.hexagonLFO, name: "Weight \(viewModel.blueConfig.config.hexagonWeight.formatted(.percent.precision(.fractionLength(0...0))))", offset: 0...1, time: viewModel.time)
                                    .tint(Color.blue)
                            }.padding()
                            
                            HStack {
                                Text("Color Offset")
                                Slider(value: $viewModel.hexagonConfig.colorOffset, in: 0.0...200.0)
                            }.padding()
                        }.frame(minWidth: 500)
                    }
                    
                    Button {
                        showLFO = true
                    } label: {
                        Label("Falloff/Bias", systemImage: "smallcircle.filled.circle.fill")
                    }.popover(isPresented: $showLFO, attachmentAnchor: .point(.top), arrowEdge: .bottom) {
                        VStack {
                            Divider()
                            LowFrequencyOscillatorControl(oscillator: $viewModel.redConfig.biasLFO, name: "Bias \(viewModel.redConfig.config.randomBias.formatted(.percent.precision(.fractionLength(0...0))))", offset: 0...1, time: viewModel.time)
                                .tint(Color.red)
                            LowFrequencyOscillatorControl(oscillator: $viewModel.greenConfig.biasLFO, name: "Bias \(viewModel.greenConfig.config.randomBias.formatted(.percent.precision(.fractionLength(0...0))))", offset: 0...1, time: viewModel.time)
                                .tint(Color.green)
                            LowFrequencyOscillatorControl(oscillator: $viewModel.blueConfig.biasLFO, name: "Bias \(viewModel.blueConfig.config.randomBias.formatted(.percent.precision(.fractionLength(0...0))))", offset: 0...1, time: viewModel.time)
                                .tint(Color.blue)
                            Divider()
                            LowFrequencyOscillatorControl(oscillator: $viewModel.redConfig.falloffLFO, name: "Falloff", offset: 0...1, time: viewModel.time)
                        }
                    }.padding()
                    
                    Button {
                        showSpeed = true
                    } label: {
                        Label("Speed", systemImage: "figure.walk.circle.fill")
                    }.popover(isPresented: $showSpeed, attachmentAnchor: .point(.top), arrowEdge: .bottom) {
                        VStack {
                            HStack {
                                Text("Starting Variance: \(viewModel.speedVariance, specifier: "%.1f")")
                                Slider(value: $viewModel.speedVariance, in: 0...3)
                            }.padding()
                            Divider()
                            LowFrequencyOscillatorControl(oscillator: $viewModel.redConfig.speedLFO, name: "Speed", offset: -1.5...1.5, time: viewModel.time)
                                .tint(Color.red)
                            LowFrequencyOscillatorControl(oscillator: $viewModel.greenConfig.speedLFO, name: "Speed", offset: -1.5...1.5, time: viewModel.time)
                                .tint(Color.green)
                            LowFrequencyOscillatorControl(oscillator: $viewModel.blueConfig.speedLFO, name: "Speed", offset: -1.5...1.5, time: viewModel.time)
                                .tint(Color.blue)
                        }
                    }.padding()
                    
                    Button {
                        self.showTurn = true
                    } label: {
                        Label("Turn Angle", systemImage: "angle")
                    }.popover(isPresented: $showTurn, attachmentAnchor: .point(.top), arrowEdge: .bottom) {
                        VStack {
                            LowFrequencyOscillatorControl(oscillator: $viewModel.redConfig.turnLFO, name: "Turn", offset: 0...2, time: viewModel.time)
                                .tint(Color.red)
                            LowFrequencyOscillatorControl(oscillator: $viewModel.greenConfig.turnLFO, name: "Turn", offset: 0...2, time: viewModel.time)
                                .tint(Color.green)
                            LowFrequencyOscillatorControl(oscillator: $viewModel.blueConfig.turnLFO, name: "Turn", offset: 0...2, time: viewModel.time)
                                .tint(Color.blue)
                        }.padding()
                    }.padding()
                    
                    //                    Button {
                    //                        showAngle = true
                    //                    } label: {
                    //                        Label("Sensor Angle", systemImage: "figure.walk.circle.fill")
                    //                    }.popover(isPresented: $showAngle) {
                    //                        VStack {
                    //                            LFOWidget(oscillator: $viewModel.redConfig.angleLFO, name: "Angle", offset: 0...1)
                    //                                .tint(Color.red)
                    //                            LFOWidget(oscillator: $viewModel.greenConfig.angleLFO, name: "Angle", offset: 0...1)
                    //                                .tint(Color.green)
                    //                            LFOWidget(oscillator: $viewModel.blueConfig.angleLFO, name: "Angle", offset: 0...1)
                    //                                .tint(Color.blue)
                    //                        }
                    //                    }.padding()
                }
                
            }.padding()
        }
        .edgesIgnoringSafeArea(.all)
        .statusBar(hidden: true)
    }
}

#Preview {
    SlimeLFOWorkshop()
}
