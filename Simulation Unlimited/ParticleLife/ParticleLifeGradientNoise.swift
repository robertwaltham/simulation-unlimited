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
    var forceMultiplier: Float = 5.0
    
    var textureSize = 256
    var scale: Float = 4.5
    var zOffset: Float = 0
    var animateOverTime = false
    var animationSpeed: Float = 0.15
    var octaves = 2
    var persistence: Float = 0.5
    var lacunarity: Float = 2
    var seed: UInt32 = 1
    
    func shaderConfig() -> ParticleLifeGradientConfig {
        var config = ParticleLifeGradientConfig()
        config.isEnabled = isEnabled ? 1 : 0
        config.isDisplayed = isDisplayed ? 1 : 0
        config.animateOverTime = animateOverTime ? 1 : 0
        config.octaves = Int32(octaves)
        config.forceMultiplier = forceMultiplier
        config.scale = scale
        config.zOffset = zOffset
        config.animationSpeed = animationSpeed
        config.persistence = persistence
        config.lacunarity = lacunarity
        config.seed = seed
        return config
    }
}

struct ParticleLifeGradientNoiseSignature: Equatable {
    let settings: ParticleLifeGradientNoiseSettings
}
