//
//  SlimeLFOWorkshop.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-02-20.
//

import SwiftUI

struct SlimeLFOWorkshop: View {
    @State var viewModel = SlimeViewModel()
    @State var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @State var showLFO = false
    @State var showSpeed = false
    @State var showAngle = false
    @State var showTurn = false

    @ViewBuilder
    private func LFOWidget(oscillator: Binding<LowFrequencyOscillator>, name: String, offset: ClosedRange<Double>) -> some View {
        HStack {
            LFOPicker(oscillator, name: name)
            LFOSlider(oscillator, offset: offset).frame(minWidth: 420)
            LFOGraph(oscillator.wrappedValue).frame(minWidth: 250, maxWidth: .infinity, maxHeight: 100)
        }
        .padding(5)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func LFOPicker(_ oscillator: Binding<LowFrequencyOscillator>, name: String) -> some View {
        VStack {
            Text(name)
            Picker("Waveform", selection: oscillator.type) {
                Text("None").tag(OscillatorType.none)
                Text("Sine").tag(OscillatorType.sine)
                Text("Square").tag(OscillatorType.square)
                Text("Sawtooth").tag(OscillatorType.sawtooth)
                Text("Triangle").tag(OscillatorType.triangle)
            }
        }
    }
    
    @ViewBuilder
    private func LFOSlider(_ oscillator: Binding<LowFrequencyOscillator>, offset: ClosedRange<Double>) -> some View {
        
        HStack {
            VStack {
                Text("FRQ: \(oscillator.wrappedValue.frequency, specifier: "%.1f")")
                Slider(value: oscillator.frequency, in: 0...2)
            }
            
            VStack {
                Text("AMP: \(oscillator.wrappedValue.amplitude, specifier: "%.1f")")
                Slider(value: oscillator.amplitude, in: 0...1)
            }
            
            VStack {
                Text("Pha: \(oscillator.wrappedValue.phase, specifier: "%.1f")")
                Slider(value: oscillator.phase, in: 0...5)
            }
            
            VStack {
                Text("Offset: \(oscillator.wrappedValue.offset, specifier: "%.2f")")
                Slider(value: oscillator.offset, in: offset)
            }

        }
    }
    
    @ViewBuilder
    private func LFOGraph(_ osc: LowFrequencyOscillator) -> some View {
        GeometryReader { reader in
            let w = reader.size.width
            let h = reader.size.height
            
            Path { path in
                path.move(to: CGPoint(x: 0, y: h/2 - CGFloat(osc.value(at: viewModel.time) / 2.0) * h/2))
                for i in 1..<Int(w) {
                    let x = CGFloat(i)
                    let y = h/2 - CGFloat(osc.value(at: (Double(i) / 40) + viewModel.time) / 2.0) * h/2
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke()
        }.clipped()
    }

    
    var body: some View {
        ZStack {
            SlimeView(viewModel: viewModel)
            .onReceive(timer, perform: { _ in
                viewModel.time += 0.01
                viewModel.update()
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
                        viewModel.time = 0
                    }
                    
                    Spacer()

                    Slider(value: $viewModel.cycleLength, in: SlimeViewModel.minCycleLength...SlimeViewModel.maxCycleLength)
                    Text("\(viewModel.cycleLength, specifier: "%.f")").foregroundStyle(Color.blue)

                    Spacer()
                    
                    Button {
                        showLFO = true
                    } label: {
                        Label("Falloff", systemImage: "figure.walk.circle.fill")
                    }.popover(isPresented: $showLFO) {
                        VStack {
                            LFOWidget(oscillator: $viewModel.redConfig.falloffLFO, name: "Falloff", offset: 0...1)
                            
                        }
                    }.padding()
                    
                    Button {
                        showSpeed = true
                    } label: {
                        Label("Speed", systemImage: "figure.walk.circle.fill")
                    }.popover(isPresented: $showSpeed) {
                        VStack {
                            LFOWidget(oscillator: $viewModel.redConfig.speedLFO, name: "Speed", offset: -1.5...1.5)
                                .tint(Color.red)
                            LFOWidget(oscillator: $viewModel.greenConfig.speedLFO, name: "Speed", offset: -1.5...1.5)
                                .tint(Color.green)
                            LFOWidget(oscillator: $viewModel.blueConfig.speedLFO, name: "Speed", offset: -1.5...1.5)
                                .tint(Color.blue)
                        }
                    }.padding()
                    
                    Button {
                        showTurn = true
                    } label: {
                        Label("Turn Angle", systemImage: "figure.walk.circle.fill")
                    }.popover(isPresented: $showTurn) {
                        VStack {
                            LFOWidget(oscillator: $viewModel.redConfig.turnLFO, name: "Turn", offset: 0...1)
                                .tint(Color.red)
                            LFOWidget(oscillator: $viewModel.greenConfig.turnLFO, name: "Turn", offset: 0...1)
                                .tint(Color.green)
                            LFOWidget(oscillator: $viewModel.blueConfig.turnLFO, name: "Turn", offset: 0...1)
                                .tint(Color.blue)
                        }
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
