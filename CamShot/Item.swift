//
//  Item.swift
//  CamShot
//
//  Created by Elizbar Kheladze on 08/12/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var id: UUID
    var timestamp: Date
    @Attribute(.externalStorage) var imageData: Data
    var audioData: Data?
    var waveform: [Float]?

    init(imageData: Data, audioData: Data?, waveform: [Float]? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.imageData = imageData
        self.audioData = audioData
        self.waveform = waveform
    }
}
