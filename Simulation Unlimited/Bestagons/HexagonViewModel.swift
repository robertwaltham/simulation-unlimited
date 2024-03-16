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
    
    var offsetX: Float = 1.0
    var offsetY: Float = 1.2
    var scaleX: Float = 126.0
    var scaleY: Float = 70.0
    var size: Float = 0.95
}
