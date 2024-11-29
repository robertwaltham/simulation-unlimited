//
//  SandViewModel.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-11-29.
//

import UIKit

class SandViewModel {
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
