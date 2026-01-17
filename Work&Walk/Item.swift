//
//  Item.swift
//  Work&Walk
//
//  Created by Alan Krieger on 17/01/2026.
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
