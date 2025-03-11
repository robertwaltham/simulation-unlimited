//
//  BoidsViewModel.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-11-15.
//

import UIKit

@Observable
class BoidsViewModel {
    
    var drawSize: Int = 3
    var count: Int = 4096
    var drawTriangles: Bool = false
    
    var redConfig = BoidsConfig.defaultConfig()
    var blueConfig = BoidsConfig.defaultConfig()
    var greenConfig = BoidsConfig.defaultConfig()
    
    var blurConfig = BlurConfig(falloff: 0.05, cutoff: 0.02, range: 3)

    convenience init(count: Int) {
        self.init()
        self.count = count
    }
    
    var touches: [UITouch: CGPoint] = [:]
    var updateCircles = true

    func updateTouch(_ touch: UITouch, location: CGPoint?) {
        if let location = location {
            touches[touch] = location
        } else {
            touches.removeValue(forKey: touch)
        }
    }
}

struct BlurConfig {
    var falloff: Float
    var cutoff: Float
    var range: Float
}


struct BoidsConfig {
    var max_speed: Float
    var min_speed: Float
    var margin: Float
    var align_coefficient: Float
    var cohere_coefficient: Float
    var separate_coefficient: Float
    var radius: Float
    var draw_scale: Float
    var variance: Float
    var ignoreOthers: Bool
    var ignoreSelf: Bool

    // padding
    var unused2: Bool = false
    var unused3: Bool = false
}

extension BoidsConfig {
    static func defaultConfig() -> BoidsConfig {
        return BoidsConfig(
            max_speed: 5,
            min_speed: 1.5,
            margin: 50,
            align_coefficient: 0.3,
            cohere_coefficient: 0.4,
            separate_coefficient: 0.5,
            radius: 30,
            draw_scale: 0.5,
            variance: 0,
            ignoreOthers: false,
            ignoreSelf: false
        )
    }
    static func altConfig() -> BoidsConfig {
        return BoidsConfig(
            max_speed: 5,
            min_speed: 1.5,
            margin: 50,
            align_coefficient: 0.1,
            cohere_coefficient: 0.1,
            separate_coefficient: 0.1,
            radius: 15,
            draw_scale: 0.5,
            variance: 0,
            ignoreOthers: true,
            ignoreSelf: false
        )
    }
}
