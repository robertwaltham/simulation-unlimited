//
//  ParticleLifeViewModel.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2023-10-11.
//

import Foundation
import SwiftUI

@Observable class ParticleLifeViewModel {
    var config = ParticleLifeConfig.defaultConfig()
    
    var minSpeed: Float = 0.75
    var maxSpeed: Float = 1.0
    
    var particleCount = 8192
    
    var margin: Float = 50
    var radius: Float = 50
    
    var drawParticles = true
    var drawPath = false
    var resetOnNext = false
    
    var startType: StartType = .random
    
    let maxSensorAngle = Float.pi / 2
    let maxDistance: Float = 15
    let maxTurnAngle = Float.pi / 4
    
    let maxCutoff: Float = 1
    let maxFalloff: Float = 0.15
    let maxRadius: Float = 4
    let maxMultiplier: Float = 6   
    
    var colours = [
        SIMD4<Float>(1, 0, 0, 1),
        SIMD4<Float>(0, 1, 0, 1),
        SIMD4<Float>(0, 0, 1, 1),
        SIMD4<Float>(0.5, 0.5, 0, 1),
        SIMD4<Float>(0, 0.5, 0.5, 1),
        SIMD4<Float>(0.5, 0, 0.5, 1),
        SIMD4<Float>(0.25, 0.75, 0, 1),
        SIMD4<Float>(0, 0.25, 0.75, 1),
        SIMD4<Float>(0.25, 0.75, 0, 1),
        SIMD4<Float>(0.5, 0.5, 0.5, 1),
    ]
}


struct ParticleLifeConfig {
    var sensorAngle: Float = 0
    var sensorDistance: Float = 0
    var turnAngle: Float = 0
    var drawRadius: Float = 0
    var trailRadius: Float = 0
    var cutoff: Float = 0
    var falloff: Float = 0
    var speedMultiplier: Float = 0
    var flavourCount = 0
    
    static func defaultConfig() -> ParticleLifeConfig {
        ParticleLifeConfig(sensorAngle: Float.pi / 8,
                           sensorDistance: 10,
                           turnAngle: Float.pi / 16,
                           drawRadius: 2,
                           trailRadius: 2,
                           cutoff: 0.01,
                           falloff: 0.02,
                           speedMultiplier: 2,
                           flavourCount: 10)
    }
}
