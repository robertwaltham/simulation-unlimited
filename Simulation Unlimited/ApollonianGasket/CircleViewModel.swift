//
//  CircleViewModel.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-03-20.
//

import Foundation
import Observation
import UIKit

@Observable
class CircleViewModel {
    var config = CircleConfig()
    let maxCircles = 500
    
    var circles = [ShaderCircle]()
    
    var touches: [UITouch: CGPoint] = [:]
    var lastCenter: CGPoint = CGPoint(x: 100, y: 100)
    var updateCircles = true

    func updateTouch(_ touch: UITouch, location: CGPoint?) {
        if let location = location {
            touches[touch] = location
            circles.removeAll()
        } else {
            touches.removeValue(forKey: touch)
        }
        
        var center2 = lastCenter
        if touches.count >= 1 {
            let points = touches.values.compactMap {$0}
            center2 = points[0]
            lastCenter = center2
            updateCircles = true
        }
    }
    
    func generateCirclesIfNeeded(size: CGSize) {
        
        guard updateCircles else {
            return
        }
        circles = Circle.circles(size: size, center: lastCenter).compactMap { c in
            c.toShader()
        }
        config.circleCount = min(Float(circles.count), Float(maxCircles))
        updateCircles = false
    }
}

struct CircleConfig {
    var radius: Float = 3.0
    var circleCount: Float = 10.0
}
