//
//  ParticleLifeViewModel.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2023-10-11.
//

import Foundation
import QuartzCore
import SwiftUI
import UIKit

@Observable final class FPSCounter {
    private let updateInterval: CFTimeInterval
    private var frameCount = 0
    private var lastUpdate = CACurrentMediaTime()
    
    var fps: Double = 0
    
    init(updateInterval: CFTimeInterval = 0.5) {
        self.updateInterval = updateInterval
    }
    
    func frameDidRender() {
        frameCount += 1
        
        let now = CACurrentMediaTime()
        let elapsed = now - lastUpdate
        
        guard elapsed >= updateInterval else {
            return
        }
        
        fps = Double(frameCount) / elapsed
        frameCount = 0
        lastUpdate = now
    }
}

@Observable class ParticleLifeViewModel {
    static let weightOptions: [Float] = (-10...10).map { Float($0) / 10 }
    private static let defaultMaxCutoff: Float = 1
    private static let defaultMaxFalloff: Float = 0.15
    private static let defaultMaxRadius: Float = 5
    private static let defaultMaxMultiplier: Float = 6
    private static let defaultMaxMinDistance: Float = 50
    private static let defaultMaxMaxDistance: Float = 200
    private static let defaultMaxParticleSpeed: Float = 10
    
    init(count: Int = 4096) {
        let initialConfig = ParticleLifeConfig.defaultConfig()
        
        self.config = initialConfig
        self.particleCount = count
        self.speedMultiplierModulation = FloatModulation(
            id: "speedMultiplier",
            name: "Speed",
            range: 0...Self.defaultMaxMultiplier,
            oscillator: LowFrequencyOscillator(type: .none, frequency: 0.5, amplitude: 1, phase: 0, offset: Double(initialConfig.speedMultiplier))
        )
        self.falloffModulation = FloatModulation(
            id: "falloff",
            name: "Falloff",
            range: 0...Self.defaultMaxFalloff,
            oscillator: LowFrequencyOscillator(type: .none, frequency: 0.5, amplitude: 1, phase: 0, offset: Double(initialConfig.falloff))
        )
        self.trailRadiusModulation = FloatModulation(
            id: "trailRadius",
            name: "Trail Size",
            range: 1...Self.defaultMaxRadius,
            oscillator: LowFrequencyOscillator(type: .none, frequency: 0.5, amplitude: 1, phase: 0, offset: Double(initialConfig.trailRadius))
        )
        self.rMinDistanceModulation = FloatModulation(
            id: "rMinDistance",
            name: "R Min",
            range: 0...Self.defaultMaxMinDistance,
            oscillator: LowFrequencyOscillator(type: .none, frequency: 0.5, amplitude: 1, phase: 0, offset: Double(initialConfig.rMinDistance))
        )
        self.rMaxDistanceModulation = FloatModulation(
            id: "rMaxDistance",
            name: "R Max",
            range: 1...Self.defaultMaxMaxDistance,
            oscillator: LowFrequencyOscillator(type: .none, frequency: 0.5, amplitude: 1, phase: 0, offset: Double(initialConfig.rMaxDistance))
        )
        self.maxSpeedModulation = FloatModulation(
            id: "maxSpeed",
            name: "S Max",
            range: 0...Self.defaultMaxParticleSpeed,
            oscillator: LowFrequencyOscillator(type: .none, frequency: 0.5, amplitude: 1, phase: 0, offset: Double(initialConfig.maxSpeed))
        )
        updateModulation(time: 0)
    }
    
    var config = ParticleLifeConfig.defaultConfig()
    let fpsCounter = FPSCounter()
    
    var minSpeed: Float = 0.75
    var maxSpeed: Float = 1.0
    
    var particleCount: Int
    
    var margin: Float = 50
    var radius: Float = 50
    
    var drawParticles = false
    var drawPath = true
    var resetOnNext = false
    var touches: [UITouch: CGPoint] = [:]
    var gradientNoiseSettings = ParticleLifeGradientNoiseSettings()
    var gradientNoiseTime = 0.0
    
    var startType: StartType = .random
    
    let maxSensorAngle = Float.pi / 2
    let maxDistance: Float = 15
    let maxTurnAngle = Float.pi / 4
    
    let maxCutoff = ParticleLifeViewModel.defaultMaxCutoff
    let maxFalloff = ParticleLifeViewModel.defaultMaxFalloff
    let maxRadius = ParticleLifeViewModel.defaultMaxRadius
    let maxMultiplier = ParticleLifeViewModel.defaultMaxMultiplier
    let maxMinDistance = ParticleLifeViewModel.defaultMaxMinDistance
    let maxMaxDistance = ParticleLifeViewModel.defaultMaxMaxDistance
    let maxParticleSpeed = ParticleLifeViewModel.defaultMaxParticleSpeed
    
    var speedMultiplierModulation: FloatModulation
    var falloffModulation: FloatModulation
    var trailRadiusModulation: FloatModulation
    var rMinDistanceModulation: FloatModulation
    var rMaxDistanceModulation: FloatModulation
    var maxSpeedModulation: FloatModulation
    
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
    
    var weights = createDefaultWeights() // TODO: de-hardcode the flavour count
    
    func getSwiftUIColors() -> [Color] {
        colours.map { c in
            Color(uiColor: UIColor(
                red: CGFloat(Self.clampedColorComponent(c.x)),
                green: CGFloat(Self.clampedColorComponent(c.y)),
                blue: CGFloat(Self.clampedColorComponent(c.z)),
                alpha: CGFloat(Self.clampedColorComponent(c.w))
            ))
        }
    }
    
    static func createDefaultWeights() -> [Float] {
        let flavourCount = 3 // TODO: remove magic number
        var defaultWeights: [Float] = Array(repeating: -1, count: flavourCount * flavourCount)
        
        for i in 0..<defaultWeights.count {
            defaultWeights[i] = Self.weightOptions.randomElement()!
        }
        
        return defaultWeights
    }
    
    func weight(x: Int, y: Int) -> Float {
        let index = x * Int(config.flavourCount) + y
        guard index < weights.count else {
            fatalError("out of bounds")
        }
        
        return weights[index]
    }
    
    func setWeight(x: Int, y: Int, value: Float) {
        let index = x * Int(config.flavourCount) + y
        guard index < weights.count else {
            fatalError("out of bounds")
        }
        
        weights[index] = Self.quantizedWeight(value)
    }
    
    func resetWeights() {
        weights = ParticleLifeViewModel.createDefaultWeights()
    }
    
    func randomizeWeights() {
        weights = stride(from: 0, to: config.flavourCount * config.flavourCount, by: 1).compactMap { _ in
            Self.weightOptions.randomElement()!
        }
    }
    
    func invertWeights() {
        weights = weights.map { Self.quantizedWeight(-$0) }
    }
    
    func updateModulation(time: Double) {
        config.speedMultiplier = speedMultiplierModulation.value(at: time)
        config.falloff = falloffModulation.value(at: time)
        config.trailRadius = trailRadiusModulation.value(at: time)
        config.rMinDistance = rMinDistanceModulation.value(at: time)
        config.rMaxDistance = rMaxDistanceModulation.value(at: time)
        config.maxSpeed = maxSpeedModulation.value(at: time)
    }
    
    func updateGradientNoiseTime(_ time: Double) {
        gradientNoiseTime = time
    }
    
    func updateTouch(_ touch: UITouch, location: CGPoint?) {
        if let location = location {
            touches[touch] = location
        } else {
            touches.removeValue(forKey: touch)
        }
    }
    
    private static func quantizedWeight(_ value: Float) -> Float {
        let tenths = Int((value * 10).rounded())
        return Float(tenths) / 10
    }
    
    private static func clampedColorComponent(_ value: Float) -> Float {
        min(max(value, 0), 1)
    }
    
}


extension ParticleLifeConfig {
    static func defaultConfig() -> ParticleLifeConfig {
        var config = ParticleLifeConfig()
        config.rMinDistance = 1
        config.rMaxDistance = 35
        config.maxSpeed = 1
        config.drawRadius = 4
        config.trailRadius = 5
        config.cutoff = 0.01
        config.falloff = 0.15
        config.speedMultiplier = 2.5
        config.flavourCount = 3
        config.blurRadius = 3
        config.padding = 0
        config.damping = 0.9
        config.forceMultiplier = 0.05
        config.touchRadius = 200
        config.touchForce = 20
        return config
    }
}
