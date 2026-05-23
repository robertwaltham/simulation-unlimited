//
//  ModulationClock.swift
//  Simulation Unlimited
//
//  Created by Codex on 2026-05-23.
//

import Foundation
import Observation

@Observable final class ModulationClock {
    var time = 0.0
    var speed = 1.0
    var isRunning = true
    
    func tick(delta: Double) {
        guard isRunning else {
            return
        }
        
        time += delta * speed
    }
    
    func reset() {
        time = 0.0
    }
}
