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
    @StateObject private var viewModel = GalleryViewModel()

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(viewModel.groupItems(items)) { section in
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
                                                waveform: item.waveform,
                                                blurAmount: 0,
                                                showAudioControls: true,
                                                enableShadow: true,
                                                isCompact: true,
                                                id: item.id
                                            )
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            viewModel.deleteItem(item, context: modelContext)
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
                        viewModel.showCapture = true
                    } label: {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.showCapture) {
                CaptureFlowView()
            }
        }
    }
}
