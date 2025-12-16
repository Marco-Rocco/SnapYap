//
//  GalleryViewModel.swift
//  CamShot
//
//  Created by Adriano Oliviero on 16/12/25.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

class GalleryViewModel: ObservableObject {
    @Published var showCapture = false

    struct MonthSection: Identifiable {
        let id = UUID()
        let title: String
        let items: [Item]
    }

    func groupItems(_ items: [Item]) -> [MonthSection] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: items) { item in
            formatter.string(from: item.timestamp)
        }

        return grouped.map { key, value in
            MonthSection(title: key, items: value)
        }.sorted { section1, section2 in
            guard let first1 = section1.items.first, let first2 = section2.items.first else { return false }
            return first1.timestamp > first2.timestamp
        }
    }

    func deleteItem(_ item: Item, context: ModelContext) {
        context.delete(item)
    }
}
