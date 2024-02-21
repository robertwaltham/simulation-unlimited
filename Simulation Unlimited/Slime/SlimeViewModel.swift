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
    var config = SlimeConfig.defaultConfig()
    
    var minSpeed: Float = 0.75
    var maxSpeed: Float = 2.0
    
    var particleCount = 8192
    
    var margin: Float = 50
    var radius: Float = 50
    
    var drawParticles = false
    var drawPath = true
    var resetOnNext = false
    
    var time = 0.0

    var startType: StartType = .circle
    
    let maxSensorAngle = Float.pi / 2
    let maxDistance: Float = 15
    let maxTurnAngle = Float.pi / 4
    
    let maxCutoff: Float = 1
    let maxFalloff: Float = 0.1
    let maxRadius: Float = 4
    let maxMultiplier: Float = 6
    
    var speedLFO = LowFrequencyOscillator(type: .none, frequency: 0.5, amplitude: 1, phase: 0, offset: 0.5)
    var angleLFO = LowFrequencyOscillator(type: .none, frequency: 0.5, amplitude: 1, phase: 0, offset: 0.25)
    var falloffLFO = LowFrequencyOscillator(type: .none, frequency: 0.5, amplitude: 1, phase: 0, offset: 0.3)

    func update() {
        config.speedMultiplier = Float(speedLFO.value(at: time)) * maxSpeed
        config.sensorAngle = Float(angleLFO.value(at: time)) * maxSensorAngle
        config.falloff = Float(falloffLFO.value(at: time)) * maxFalloff
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
}

extension SlimeConfig {
    static func defaultConfig() -> SlimeConfig {
        SlimeConfig(sensorAngle: Float.pi / 8,
                    sensorDistance: 10,
                    turnAngle: Float.pi / 16,
                    drawRadius: 2,
                    trailRadius: 2,
                    cutoff: 0.01,
                    falloff: 0.02,
                    speedMultiplier: 2)
    }
}

