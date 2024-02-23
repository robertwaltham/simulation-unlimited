//
//  LowFrequencyOscillator.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-02-20.
//

import Foundation


enum OscillatorType {
    case none
    case sine
    case square
    case sawtooth
    case triangle
}


struct LowFrequencyOscillator {
    var type: OscillatorType
    var frequency: Double
    var amplitude: Double
    var phase: Double
    var offset: Double
    
    func value(at time: Double) -> Double {
        let t = abs(time * frequency + phase)
        switch type {
        case .none:
            return offset
        case .sine:
            return offset + sin(t * 4) * amplitude
        case .square:
            return (sin(t * 4) > 0 ? amplitude : -amplitude) + offset
        case .sawtooth:
            let t = time * frequency + (phase / 4)
            return (2 * (t - floor(0.5 + t)) * amplitude) + offset
        case .triangle:
            let period = 1.0 / frequency
            let currentTime = fmod(time + phase, period)
            let value = currentTime / period
            
            
            var result: Double = 0.0
            if value < 0.25 {
                result = value * 4
            } else if value < 0.75 {
                result = 2.0 - (value * 4.0)
            } else {
                result = value * 4 - 4.0
            }
            return (amplitude * result) + offset
        }
    }
}
