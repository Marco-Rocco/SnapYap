//
//  Item.swift
//  CamShot
//
//  Created by Elizbar Kheladze on 08/12/25.
//

import SwiftData
import Foundation

@Model
final class Item {
    var id: UUID
    var timestamp: Date
    @Attribute(.externalStorage) var imageData: Data
    var audioData: Data?

    init(imageData: Data, audioData: Data?) {
        self.id = UUID()
        self.timestamp = Date()
        self.imageData = imageData
        self.audioData = audioData
    }
}
