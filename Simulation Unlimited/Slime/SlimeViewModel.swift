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
    var maxSpeed: Float = 1.0
    
    var particleCount = 8192
    
    var margin: Float = 50
    var radius: Float = 50
    
    var drawParticles = false
    var drawPath = true

    var startType: StartType = .random
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

