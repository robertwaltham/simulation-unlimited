//
//  ParticleLifeViewModel.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2023-10-11.
//

import Foundation

@Observable class ParticleLifeViewModel {
    var config = SlimeConfig.defaultConfig()
    
    var minSpeed: Float = 0.75
    var maxSpeed: Float = 1.0
    
    var particleCount = 8192
    
    var margin: Float = 50
    var radius: Float = 50
    
    var drawParticles = false
    var drawPath = true
    var resetOnNext = false

    var startType: StartType = .circle
    
    let maxSensorAngle = Float.pi / 2
    let maxDistance: Float = 15
    let maxTurnAngle = Float.pi / 4
    
    let maxCutoff: Float = 1
    let maxFalloff: Float = 0.15
    let maxRadius: Float = 4
    let maxMultiplier: Float = 6
}
