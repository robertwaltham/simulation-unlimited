//
//  SlimeViewModel.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2023-10-04.
//

import Foundation
import Observation
import SwiftUI

enum StartType: Int, CaseIterable, Identifiable {
    case random = 1
    case lines = 2
    case grid = 3
    case circle = 4
    
    var id: String { self.rawValue.description }
    
    var label : some View {
        switch(self) {
        
        case .random:
            return Label("Random", systemImage: "square")
        case .lines:
            return Label("Lines", systemImage: "equal")
        case .grid:
            return Label("Grid", systemImage: "number")
        case .circle:
            return Label("Circle", systemImage: "circle")
        }
    }
}


@Observable class SlimeViewModel {
    var redConfig = ColorConfig(color: .red)
    var greenConfig = ColorConfig(color: .green)
    var blueConfig = ColorConfig(color: .blue)
    
    var hexagonConfig = HexagonConfig()

    var particleCount = 8192
    
    var margin: Float = 50
    var radius: Float = 50
    
    var drawParticles = false
    var drawPath = true
    var resetOnNext = false
    
    var time = 0.0
    var cycleLength = 100.0
    static let maxCycleLength = 100.0
    static let minCycleLength = 1.0
    
    var speedVariance: Float = 1.3
    static let baseSpeed: Float = 0.7
    
    var startType: StartType = .circle

    func update() {
        redConfig.updateConfig(time: time)
        greenConfig.updateConfig(time: time)
        blueConfig.updateConfig(time: time)
        if time > cycleLength {
            resetOnNext = true
            time = 0.0
        }
    }
}

enum SlimeColor {
    case red
    case green
    case blue
}

struct ColorConfig {
    let color: SlimeColor
    
    var config = SlimeConfig.defaultConfig()
    
    var speedLFO = LowFrequencyOscillator(type: .none, frequency: 0.5, amplitude: 1, phase: 0, offset: 0.7)
    var angleLFO = LowFrequencyOscillator(type: .none, frequency: 0.5, amplitude: 1, phase: 0, offset: 0.25)
    var falloffLFO = LowFrequencyOscillator(type: .none, frequency: 0.5, amplitude: 1, phase: 0, offset: 0.2)
    var turnLFO = LowFrequencyOscillator(type: .none, frequency: 0.5, amplitude: 1, phase: 0, offset: 0.3)
    var biasLFO = LowFrequencyOscillator(type: .none, frequency: 0.5, amplitude: 1, phase: 0, offset: 0.5)
    var hexagonLFO = LowFrequencyOscillator(type: .none, frequency: 0.5, amplitude: 1, phase: 0, offset: 0.0)

    mutating func updateConfig(time: Double) {
        config.speedMultiplier = Float(speedLFO.value(at: time)) * SlimeConfig.maxSpeed
        config.sensorAngle = Float(angleLFO.value(at: time)) * SlimeConfig.maxSensorAngle
        config.falloff = Float(falloffLFO.value(at: time)) * SlimeConfig.maxFalloff
        config.turnAngle = Float(turnLFO.value(at: time)) * SlimeConfig.maxTurnAngle
        config.randomBias = Float(biasLFO.value(at: time)) // 0 -> 1
        config.hexagonWeight = max(min(Float(hexagonLFO.value(at: time)), 1.0), 0.0)
    }
}

struct SlimeConfig {
    var sensorAngle: Float = 0
    var sensorDistance: Float = 0
    var turnAngle: Float = 0
    var drawRadius: Float = 0
    var trailRadius: Float = 0
    var cutoff: Float = 0
    var falloff: Float = 0
    var speedMultiplier: Float = 0
    var randomBias: Float = 0
    var blurSize: Float = 0
    var hexagonWeight: Float = 0
    
    static let maxSensorAngle = Float.pi / 2
    static let maxDistance: Float = 15
    static let maxTurnAngle = Float.pi / 4
    
    static let maxCutoff: Float = 1
    static let maxFalloff: Float = 0.1
    static let maxRadius: Float = 4
    static let maxMultiplier: Float = 6
    static let maxSpeed: Float = 2.0
}

extension SlimeConfig {
    static func defaultConfig() -> SlimeConfig {
        SlimeConfig(sensorAngle: Float.pi / 8,
                    sensorDistance: 10,
                    turnAngle: Float.pi / 16,
                    drawRadius: 5,
                    trailRadius: 4,
                    cutoff: 0.01,
                    falloff: 0.02,
                    speedMultiplier: 2,
                    randomBias: 0.5,
                    blurSize: 1.0)
    }
}

