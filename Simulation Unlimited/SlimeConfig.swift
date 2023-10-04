//
//  SlimeConfig.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2023-09-30.
//

import Foundation

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
