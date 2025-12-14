//
//  GalleryView.swift
//  CamShot
//
//  Created by Elizbar Kheladze on 08/12/25.
//

import SwiftData
import SwiftUI

struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.timestamp, order: .reverse) private var items: [Item]
    @State private var showCapture = false

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    struct MonthSection: Identifiable {
        let id = UUID()
        let title: String
        let items: [Item]
    }

    var groupedItems: [MonthSection] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        let grouped = Dictionary(grouping: items) { item in
            formatter.string(from: item.timestamp)
        }
        
        return grouped.map { (key, value) in
            MonthSection(title: key, items: value)
        }.sorted { section1, section2 in
            guard let first1 = section1.items.first, let first2 = section2.items.first else { return false }
            return first1.timestamp > first2.timestamp
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    
                    ForEach(groupedItems) { section in
                        VStack(alignment: .leading, spacing: 10) {

                            Text(section.title)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.top, 10)

                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(section.items) { item in
                                    NavigationLink(destination: ItemDetailView(selectedID: item.id)) {
                                        if let uiImage = UIImage(data: item.imageData) {
                                            PolaroidFrame(
                                                image: uiImage,
                                                audioData: item.audioData,
                                                blurAmount: 0,
                                                showAudioControls: true,
                                                enableShadow: true,
                                                isCompact: true
                                            )
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteItem(item)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color.main)
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCapture = true
                    } label: {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .fullScreenCover(isPresented: $showCapture) {
                CaptureFlowView()
            }
        }
    }

    private func deleteItem(_ item: Item) {
        withAnimation {
            modelContext.delete(item)
        }
    }
}
