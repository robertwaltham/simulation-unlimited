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
    
    var particleCount = 1024
    
    var margin: Float = 50
    var radius: Float = 50
    
    var drawParticles = false
    var drawPath = true
    var resetOnNext = false
    
    var startType: StartType = .random
    
    let maxSensorAngle = Float.pi / 2
    let maxDistance: Float = 15
    let maxTurnAngle = Float.pi / 4
    
    let maxCutoff: Float = 1
    let maxFalloff: Float = 0.15
    let maxRadius: Float = 5
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
        SIMD4<Float>(0.25, 0, 0.75, 1),
        SIMD4<Float>(0.5, 0.5, 0.5, 1),
    ]
    
    var weights = createDefaultWeights(flavourCount: 3) // TODO: de-hardcode the flavour count
    
    func getSwiftUIColors() -> [Color] {
        colours.map { c in
            Color(uiColor: UIColor(red: CGFloat(c.x), green: CGFloat(c.y), blue: CGFloat(c.z), alpha: CGFloat(c.w)))
        }
    }
    
    static func createDefaultWeights(flavourCount: Int) -> [Float] {
        var defaultWeights: [Float] = Array(repeating: -0.5, count: flavourCount * flavourCount)
        
        for i in 0..<flavourCount {
            defaultWeights[(i * flavourCount) + i] = 0.5
        }
        
        return defaultWeights
    }
    
    func weight(x: Int, y: Int) -> Float {
        let index = x * config.flavourCount + y
        guard index < weights.count else {
            fatalError("out of bounds")
        }
        
        return weights[index]
    }
    
    func setWeight(x: Int, y: Int, value: Float) {
        let index = x * config.flavourCount + y
        guard index < weights.count else {
            fatalError("out of bounds")
        }
        
        weights[index] = value
    }
    
    func resetWeights() {
        weights = ParticleLifeViewModel.createDefaultWeights(flavourCount: config.flavourCount)
    }
    
    func randomizeWeights() {
        let values: [Float] = stride(from: -1.0, to: 1, by: 0.5).compactMap {$0}
        weights = stride(from: 0, to: config.flavourCount * config.flavourCount, by: 1).compactMap { _ in values.randomElement()! }
    }
    
}


struct ParticleLifeConfig {
    var rMinDistance: Float = 0
    var rMaxDistance: Float = 0
    var maxSpeed: Float = 0
    var drawRadius: Float = 0
    var trailRadius: Float = 0
    var cutoff: Float = 0
    var falloff: Float = 0
    var speedMultiplier: Float = 0
    var flavourCount = 0
    
    static func defaultConfig() -> ParticleLifeConfig {
        ParticleLifeConfig(rMinDistance: 1,
                           rMaxDistance: 15,
                           maxSpeed: 10,
                           drawRadius: 4,
                           trailRadius: 4,
                           cutoff: 0.01,
                           falloff: 0.02,
                           speedMultiplier: 2,
                           flavourCount: 2)
    }
}
