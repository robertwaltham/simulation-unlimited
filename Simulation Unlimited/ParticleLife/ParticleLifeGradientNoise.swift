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
    
    func shaderConfig() -> ParticleLifeGradientConfig {
        var config = ParticleLifeGradientConfig()
        config.isEnabled = isEnabled ? 1 : 0
        config.isDisplayed = isDisplayed ? 1 : 0
        config.forceMultiplier = forceMultiplier
        config.padding = 0
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

enum ParticleLifeGradientNoise {
    static func makePixels(settings: ParticleLifeGradientNoiseSettings, zValue: Float) -> [UInt8] {
        let size = max(settings.textureSize, 2)
        let generator = Perlin3D(seed: settings.seed)
        var pixels = Array(repeating: UInt8(0), count: size * size)
        
        for y in 0..<size {
            for x in 0..<size {
                let u = Float(x) / Float(size - 1)
                let v = Float(y) / Float(size - 1)
                let value = octaveNoise(
                    x: u * settings.scale,
                    y: v * settings.scale,
                    z: zValue,
                    octaves: max(settings.octaves, 1),
                    persistence: settings.persistence,
                    lacunarity: settings.lacunarity,
                    generator: generator
                )
                let normalized = min(max((value + 1) * 0.5, 0), 1)
                pixels[y * size + x] = UInt8((normalized * 255).rounded())
            }
        }
        
        return pixels
    }
    
    private static func octaveNoise(
        x: Float,
        y: Float,
        z: Float,
        octaves: Int,
        persistence: Float,
        lacunarity: Float,
        generator: Perlin3D
    ) -> Float {
        var total: Float = 0
        var frequency: Float = 1
        var amplitude: Float = 1
        var maxValue: Float = 0
        
        for _ in 0..<octaves {
            total += generator.noise(x: x * frequency, y: y * frequency, z: z * frequency) * amplitude
            maxValue += amplitude
            amplitude *= persistence
            frequency *= lacunarity
        }
        
        guard maxValue > 0 else {
            return 0
        }
        
        return total / maxValue
    }
}

private struct Perlin3D {
    private let permutation: [Int]
    
    init(seed: UInt32) {
        var values = Array(0..<256)
        var random = SeededRandom(seed: seed)
        
        for index in stride(from: values.count - 1, through: 1, by: -1) {
            let swapIndex = Int(random.next() % UInt32(index + 1))
            values.swapAt(index, swapIndex)
        }
        
        permutation = values + values
    }
    
    func noise(x: Float, y: Float, z: Float) -> Float {
        let xi = Int(floor(x)) & 255
        let yi = Int(floor(y)) & 255
        let zi = Int(floor(z)) & 255
        
        let xf = x - floor(x)
        let yf = y - floor(y)
        let zf = z - floor(z)
        
        let u = fade(xf)
        let v = fade(yf)
        let w = fade(zf)
        
        let aaa = permutation[permutation[permutation[xi] + yi] + zi]
        let aba = permutation[permutation[permutation[xi] + yi + 1] + zi]
        let aab = permutation[permutation[permutation[xi] + yi] + zi + 1]
        let abb = permutation[permutation[permutation[xi] + yi + 1] + zi + 1]
        let baa = permutation[permutation[permutation[xi + 1] + yi] + zi]
        let bba = permutation[permutation[permutation[xi + 1] + yi + 1] + zi]
        let bab = permutation[permutation[permutation[xi + 1] + yi] + zi + 1]
        let bbb = permutation[permutation[permutation[xi + 1] + yi + 1] + zi + 1]
        
        let x1 = lerp(grad(hash: aaa, x: xf, y: yf, z: zf),
                      grad(hash: baa, x: xf - 1, y: yf, z: zf),
                      u)
        let x2 = lerp(grad(hash: aba, x: xf, y: yf - 1, z: zf),
                      grad(hash: bba, x: xf - 1, y: yf - 1, z: zf),
                      u)
        let y1 = lerp(x1, x2, v)
        
        let x3 = lerp(grad(hash: aab, x: xf, y: yf, z: zf - 1),
                      grad(hash: bab, x: xf - 1, y: yf, z: zf - 1),
                      u)
        let x4 = lerp(grad(hash: abb, x: xf, y: yf - 1, z: zf - 1),
                      grad(hash: bbb, x: xf - 1, y: yf - 1, z: zf - 1),
                      u)
        let y2 = lerp(x3, x4, v)
        
        return lerp(y1, y2, w)
    }
    
    private func fade(_ t: Float) -> Float {
        t * t * t * (t * (t * 6 - 15) + 10)
    }
    
    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + t * (b - a)
    }
    
    private func grad(hash: Int, x: Float, y: Float, z: Float) -> Float {
        let h = hash & 15
        let u = h < 8 ? x : y
        let v = h < 4 ? y : (h == 12 || h == 14 ? x : z)
        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
    }
}

private struct SeededRandom {
    private var state: UInt32
    
    init(seed: UInt32) {
        state = seed == 0 ? 1 : seed
    }
    
    mutating func next() -> UInt32 {
        state = 1664525 &* state &+ 1013904223
        return state
    }
}
