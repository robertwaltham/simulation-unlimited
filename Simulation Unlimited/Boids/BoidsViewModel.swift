//
//  BoidsViewModel.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-11-15.
//

import UIKit

@Observable
class BoidsViewModel {
    
    var drawSize: Int = 2
    var count: Int = 4096
    
    var config = BoidsConfig.defaultConfig()
    
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


struct BoidsConfig {
    var max_speed: Float
    var margin: Float
    var align_coefficient: Float
    var cohere_coefficient: Float
    var separate_coefficient: Float
    var radius: Float
}

extension BoidsConfig {
    static func defaultConfig() -> BoidsConfig {
        return BoidsConfig(
            max_speed: 5,
            margin: 50,
            align_coefficient: 0.3,
            cohere_coefficient: 0.4,
            separate_coefficient: 0.5,
            radius: 15
        )
    }
}
