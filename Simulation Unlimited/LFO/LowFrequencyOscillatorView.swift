//
//  LowFrequencyOscillatorView.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-02-20.
//

import SwiftUI

struct LowFrequencyOscillatorView: View {
    @State var oscillator = LowFrequencyOscillator(type: .sine, frequency: 1, amplitude: 1, phase: 0, offset: 0)
    @State var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @State var time: Double = 0.0
    
    var body: some View {
        
        VStack (spacing: 40) {

            HStack {
                Text("\(time, specifier: "%.2f")")
                Text("\(oscillator.value(at: time), specifier: "%.2f")")
            }


            HStack {
                slider($oscillator).frame(width: 300)
                picker($oscillator).padding()
                graph(oscillator).frame(maxWidth: .infinity, maxHeight: 100)
            }
            .padding()
            .foregroundColor(.blue)
            .background(Color(white: 0.9))
            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 20)))

        }
        .padding()

        .onReceive(timer) { _ in
            time += 0.01
        }
    }
    
    @ViewBuilder
    private func picker(_ oscillator: Binding<LowFrequencyOscillator>) -> some View {
        Picker("Waveform", selection: oscillator.type) {
            Text("None").tag(OscillatorType.none)
            Text("Sine").tag(OscillatorType.sine)
            Text("Square").tag(OscillatorType.square)
            Text("Sawtooth").tag(OscillatorType.sawtooth)
            Text("Triangle").tag(OscillatorType.triangle)
        }
    }
    
    @ViewBuilder
    private func slider(_ oscillator: Binding<LowFrequencyOscillator>) -> some View {
        
        HStack {
            VStack {
                Text("FRQ: \(oscillator.wrappedValue.frequency, specifier: "%.2f")")
                    .font(.title3)
                Slider(value: $oscillator.frequency, in: 0...2)
            }
            
            VStack {
                Text("AMP: \(oscillator.wrappedValue.amplitude, specifier: "%.2f")")
                    .font(.title3)
                Slider(value: $oscillator.amplitude, in: 0...1)
            }
            
            VStack {
                Text("Pha: \(oscillator.wrappedValue.phase, specifier: "%.2f")")
                    .font(.title3)
                Slider(value: $oscillator.phase, in: 0...5)
            }
        }
    }
    
    @ViewBuilder
    private func graph(_ osc: LowFrequencyOscillator) -> some View {
        GeometryReader { reader in
            let w = reader.size.width
            let h = reader.size.height
            
            Path { path in
                path.move(to: CGPoint(x: 0, y: h/2 - CGFloat(osc.value(at: time)) * h/2))
                for i in 1..<Int(w) {
                    let x = CGFloat(i)
                    let y = h/2 - CGFloat(osc.value(at: (Double(i) / 20) + time)) * h/2
                    path.addLine(to: CGPoint(x: x, y: y))
                }

            }.stroke()
        }.clipped()
    }
}



#Preview {
    LowFrequencyOscillatorView()
}
