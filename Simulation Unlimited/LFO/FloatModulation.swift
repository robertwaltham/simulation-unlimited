//
//  FloatModulation.swift
//  Simulation Unlimited
//
//  Created by Codex on 2026-05-23.
//

import Foundation

struct FloatModulation: Identifiable {
    let id: String
    let name: String
    let range: ClosedRange<Float>
    var oscillator: LowFrequencyOscillator
    
    var amplitudeRange: ClosedRange<Double> {
        0...Double(max(abs(range.lowerBound), abs(range.upperBound)))
    }
    
    var graphValueScale: CGFloat {
        let maxAmplitude = max(abs(range.lowerBound), abs(range.upperBound))
        guard maxAmplitude > 0 else {
            return 1
        }
        
        return 1 / CGFloat(maxAmplitude)
    }
    
    func value(at time: Double) -> Float {
        let value = Float(oscillator.value(at: time))
        return min(max(value, range.lowerBound), range.upperBound)
    }
}
