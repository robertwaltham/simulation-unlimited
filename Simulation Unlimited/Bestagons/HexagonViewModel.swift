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
    
    var config: HexagonConfig
    
    init(config: HexagonConfig = .defaultConfig()) {
        self.config = config
    }
    
}

extension HexagonConfig {
    init(
        offsetX: Float,
        offsetY: Float,
        shiftX: Float,
        shiftY: Float,
        size: Float,
        modX: Float,
        modY: Float,
        multiplier: Float,
        colorOffset: Float
    ) {
        self.init()
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.shiftX = shiftX
        self.shiftY = shiftY
        self.size = size
        self.modX = modX
        self.modY = modY
        self.multiplier = multiplier
        self.colorOffset = colorOffset
    }
    
    init(shiftX: Float, shiftY: Float) {
        self.init(
            offsetX: 1.1,
            offsetY: 1.0,
            shiftX: shiftX,
            shiftY: shiftY,
            size: 0.9,
            modX: 3.5,
            modY: 2.0,
            multiplier: 30.0,
            colorOffset: 0.0
        )
    }
    
    static func defaultConfig() -> HexagonConfig {
        HexagonConfig(
            offsetX: 1.1,
            offsetY: 1.0,
            shiftX: 136.5,
            shiftY: 76.5,
            size: 0.9,
            modX: 3.5,
            modY: 2.0,
            multiplier: 30.0,
            colorOffset: 0.0
        )
    }
}
