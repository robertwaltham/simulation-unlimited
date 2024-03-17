//
//  HexagonViewModel.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2024-03-16.
//

import Foundation
import Observation

@Observable
class HexagonViewModel {
    
    var config = HexagonConfig()
    
}

struct HexagonConfig {
    // TODO: fix these for different resolutions
    var offsetX: Float = 1.1
    var offsetY: Float = 1.0
    var shiftX: Float = 136.5
    var shiftY: Float = 76.5
    var size: Float = 0.9
    var modX: Float = 3.5
    var modY: Float = 2.0
    var multiplier: Float = 30.0
    var colorOffset: Float = 0.0
}
