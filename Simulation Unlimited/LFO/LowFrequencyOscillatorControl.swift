//
//  LowFrequencyOscillatorControl.swift
//  Simulation Unlimited
//
//  Created by Codex on 2026-05-23.
//

import SwiftUI

struct LowFrequencyOscillatorControl: View {
    @Binding var oscillator: LowFrequencyOscillator
    
    let name: String
    let offset: ClosedRange<Double>
    let amplitude: ClosedRange<Double>
    let time: Double
    let graphValueScale: CGFloat
    let graphSampleDivisor: Double
    
    init(
        oscillator: Binding<LowFrequencyOscillator>,
        name: String,
        offset: ClosedRange<Double>,
        amplitude: ClosedRange<Double> = 0...1,
        time: Double,
        graphValueScale: CGFloat = 0.5,
        graphSampleDivisor: Double = 40
    ) {
        self._oscillator = oscillator
        self.name = name
        self.offset = offset
        self.amplitude = amplitude
        self.time = time
        self.graphValueScale = graphValueScale
        self.graphSampleDivisor = graphSampleDivisor
    }
    
    var body: some View {
        HStack {
            LowFrequencyOscillatorPicker(oscillator: $oscillator, name: name)
            LowFrequencyOscillatorSliders(oscillator: $oscillator, offset: offset, amplitude: amplitude)
                .frame(minWidth: 420)
            LowFrequencyOscillatorGraph(
                oscillator: oscillator,
                time: time,
                valueScale: graphValueScale,
                sampleDivisor: graphSampleDivisor
            )
            .frame(minWidth: 250, maxWidth: .infinity, maxHeight: 100)
        }
        .padding(5)
        .frame(maxWidth: .infinity)
    }
}

struct FloatModulationControl: View {
    @Binding var modulation: FloatModulation
    
    let time: Double
    
    var body: some View {
        LowFrequencyOscillatorControl(
            oscillator: $modulation.oscillator,
            name: "\(modulation.name): \(modulation.value(at: time).formatted(.number.precision(.fractionLength(2))))",
            offset: Double(modulation.range.lowerBound)...Double(modulation.range.upperBound),
            amplitude: modulation.amplitudeRange,
            time: time,
            graphValueScale: modulation.graphValueScale
        )
    }
}

private struct LowFrequencyOscillatorPicker: View {
    @Binding var oscillator: LowFrequencyOscillator
    
    let name: String
    
    var body: some View {
        VStack {
            Text(name).frame(minWidth: 150)
            Picker("Waveform", selection: $oscillator.type) {
                Text("None").tag(OscillatorType.none)
                Text("Sine").tag(OscillatorType.sine)
                Text("Square").tag(OscillatorType.square)
                Text("Sawtooth").tag(OscillatorType.sawtooth)
                Text("Triangle").tag(OscillatorType.triangle)
            }
        }
        .padding(.leading, 10)
    }
}

private struct LowFrequencyOscillatorSliders: View {
    @Binding var oscillator: LowFrequencyOscillator
    
    let offset: ClosedRange<Double>
    let amplitude: ClosedRange<Double>
    
    var body: some View {
        HStack {
            VStack {
                Text("FRQ: \(oscillator.frequency, specifier: "%.1f")")
                Slider(value: $oscillator.frequency, in: 0...2)
            }
            
            VStack {
                Text("AMP: \(oscillator.amplitude, specifier: "%.2f")")
                Slider(value: $oscillator.amplitude, in: amplitude)
            }
            
            VStack {
                Text("Pha: \(oscillator.phase, specifier: "%.1f")")
                Slider(value: $oscillator.phase, in: 0...5)
            }
            
            VStack {
                Text("Offset: \(oscillator.offset, specifier: "%.2f")")
                Slider(value: $oscillator.offset, in: offset)
            }
        }
    }
}

struct LowFrequencyOscillatorGraph: View {
    let oscillator: LowFrequencyOscillator
    let time: Double
    let valueScale: CGFloat
    let sampleDivisor: Double
    
    var body: some View {
        GeometryReader { reader in
            let w = reader.size.width
            let h = reader.size.height
            
            Path { path in
                path.move(to: point(x: 0, height: h))
                for i in 1..<Int(w) {
                    let x = CGFloat(i)
                    path.addLine(to: point(x: x, height: h))
                }
            }
            .stroke()
        }
        .clipped()
    }
    
    private func point(x: CGFloat, height: CGFloat) -> CGPoint {
        let sampleTime = (Double(x) / sampleDivisor) + time
        let y = height / 2 - CGFloat(oscillator.value(at: sampleTime)) * valueScale * height / 2
        return CGPoint(x: x, y: y)
    }
}
