//
//  ParticleLifeGradientNoise.swift
//  Simulation Unlimited
//
//  Created by Codex on 2026-05-23.
//

import Foundation

struct ParticleLifeGradientNoiseSettings: Equatable {
    var isEnabled = false
    var isDisplayed = false
    var forceMultiplier: Float = 0.05
    
    var textureSize = 256
    var scale: Float = 3
    var zOffset: Float = 0
    var animateOverTime = false
    var animationSpeed: Float = 0.15
    var octaves = 4
    var persistence: Float = 0.5
    var lacunarity: Float = 2
    var seed: UInt32 = 1
    
    func shaderConfig(time: Double) -> ParticleLifeGradientConfig {
        var config = ParticleLifeGradientConfig()
        config.isEnabled = isEnabled ? 1 : 0
        config.isDisplayed = isDisplayed ? 1 : 0
        config.animateOverTime = animateOverTime ? 1 : 0
        config.octaves = Int32(octaves)
        config.forceMultiplier = forceMultiplier
        config.scale = scale
        config.zOffset = zValue(at: time)
        config.animationSpeed = animationSpeed
        config.persistence = persistence
        config.lacunarity = lacunarity
        config.seed = seed
        return config
    }
    
    func zValue(at time: Double) -> Float {
        guard animateOverTime else {
            return zOffset
        }
        
        return zOffset + Float(time) * animationSpeed
    }
}

struct ParticleLifeGradientNoiseSignature: Equatable {
    let settings: ParticleLifeGradientNoiseSettings
    let zValue: Float
}
