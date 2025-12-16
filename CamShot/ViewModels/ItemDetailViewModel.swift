//
//  ItemDetailViewModel.swift
//  CamShot
//
//  Created by Adriano Oliviero on 16/12/25.
//

import Combine
import Foundation
import SwiftUI

class ItemDetailViewModel: ObservableObject {
    @Published var selectedID: UUID
    @Published var flippedIDs: Set<UUID> = []

    init(selectedID: UUID) {
        self.selectedID = selectedID
    }

    func isFlipped(_ id: UUID) -> Bool {
        flippedIDs.contains(id)
    }

    func setFlipped(_ id: UUID, isFlipped: Bool) {
        if isFlipped {
            flippedIDs.insert(id)
        } else {
            flippedIDs.remove(id)
        }
    }

    func toggleFlip(_ id: UUID) {
        if flippedIDs.contains(id) {
            flippedIDs.remove(id)
        } else {
            flippedIDs.insert(id)
        }
    }
}
