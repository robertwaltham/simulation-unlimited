//
//  Item.swift
//  Simulation Unlimited
//
//  Created by Robert Waltham on 2023-09-29.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
