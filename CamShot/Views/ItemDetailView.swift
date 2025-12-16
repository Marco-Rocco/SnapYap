//
//  ItemDetailView.swift
//  CamShot
//
//  Created by Elizbar Kheladze on 08/12/25.
//

import SwiftData
import SwiftUI

struct ItemDetailView: View {
    @Query(sort: \Item.timestamp, order: .reverse) private var items: [Item]
    @StateObject private var viewModel: ItemDetailViewModel

    let thumbnailSize: CGFloat = 40
    let thumbnailSpacing: CGFloat = 8

    init(selectedID: UUID) {
        _viewModel = StateObject(wrappedValue: ItemDetailViewModel(selectedID: selectedID))
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("EEE d MMM, HH:mm")
        return f
    }()

    var body: some View {
        ZStack {
            Color.main.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                TabView(selection: $viewModel.selectedID) {
                    ForEach(items) { item in
                        if let uiImage = UIImage(data: item.imageData) {
                            VStack {
                                Spacer()

                                // Flip card wrapper
                                FlipCard(
                                    isFlipped: Binding(
                                        get: { viewModel.isFlipped(item.id) },
                                        set: { newValue in
                                            viewModel.setFlipped(item.id, isFlipped: newValue)
                                        }
                                    ),
                                    front: {
                                        PolaroidFrame(
                                            image: uiImage,
                                            audioData: item.audioData,
                                            waveform: item.waveform,
                                            blurAmount: 0,
                                            showAudioControls: true,
                                            enableShadow: false,
                                            id: item.id
                                        )
                                    },
                                    back: {
                                        ZStack {
                                            PolaroidFrame(
                                                image: uiImage,
                                                audioData: item.audioData,
                                                waveform: item.waveform,
                                                blurAmount: 0,
                                                showAudioControls: true,
                                                enableShadow: false,
                                                id: item.id
                                            ).scaleEffect(x: -1)
                                                .opacity(0.3)
                                                .overlay {
                                                    Color.white
                                                }.opacity(0.6)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                            Text(Self.dateFormatter.string(from: item.timestamp))
                                                .opacity(0.8)
                                                .font(.system(size: 28, weight: .bold))
                                                .foregroundColor(.black)
                                                .padding(.leading, 20)
                                                .padding(.bottom, 12)
                                                .tag(item.id)
                                        }
                                    }
                                )
                                .padding(.horizontal, 20)

                                Spacer()
                            }
                            .tag(item.id)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                GeometryReader { geo in
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: thumbnailSpacing) {
                                Spacer()
                                    .frame(width: max(0, geo.size.width / 2 - thumbnailSize / 2 - thumbnailSpacing))

                                ForEach(items) { item in
                                    if let uiImage = UIImage(data: item.imageData) {
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                viewModel.selectedID = item.id
                                            }
                                        } label: {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: thumbnailSize, height: thumbnailSize)
                                                .clipped()
                                                .opacity(viewModel.selectedID == item.id ? 1.0 : 0.5)
                                                .border(Color.white, width: viewModel.selectedID == item.id ? 2 : 0)
                                        }
                                        .id(item.id)
                                    }
                                }

                                Spacer()
                                    .frame(width: max(0, geo.size.width / 2 - thumbnailSize / 2 - thumbnailSpacing))
                            }
                            .padding(.bottom, 20)
                        }
                        .frame(height: 60)
                        .onChange(of: viewModel.selectedID) { _, newID in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(newID, anchor: .center)
                            }
                        }
                        .onAppear {
                            proxy.scrollTo(viewModel.selectedID, anchor: .center)
                        }
                    }
                }
                .frame(height: 60)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// MARK: - FlipCard inline view

private struct FlipCard<Front: View, Back: View>: View {
    @Binding var isFlipped: Bool
    let front: Front
    let back: Back

    // Animation state
    @State private var rotation: Double = 0
    @State private var pressing: Bool = false

    init(
        isFlipped: Binding<Bool>,
        @ViewBuilder front: () -> Front,
        @ViewBuilder back: () -> Back
    ) {
        self._isFlipped = isFlipped
        self.front = front()
        self.back = back()
    }

    var body: some View {
        ZStack {
            // Front (only the card flips)
            front
                .opacity(isFrontVisible ? 1 : 0)
                .accessibilityHidden(!isFrontVisible)
                .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                .animation(.easeInOut(duration: 0.35), value: rotation)

            // Back (same)
            ZStack {
                back
            }
            .opacity(isFrontVisible ? 0 : 1)
            .accessibilityHidden(isFrontVisible)
            .rotation3DEffect(.degrees(rotation + 180), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .animation(.easeInOut(duration: 0.35), value: rotation)
        }
        .modifier(FlipShadow(isFlipped: isFlipped))
        .onChange(of: isFlipped) { _, newValue in
            withAnimation(.easeInOut(duration: 0.35)) {
                rotation = newValue ? 180 : 0
            }
        }
        .onAppear {
            rotation = isFlipped ? 180 : 0
        }
        .onLongPressGesture(minimumDuration: 0.25, perform: {
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
            withAnimation(.easeInOut(duration: 0.35)) {
                isFlipped.toggle()
            }
        }, onPressingChanged: { isPressing in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                pressing = isPressing
            }
        })
        .scaleEffect(pressing ? 0.98 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: pressing)
    }

    private var isFrontVisible: Bool {
        rotation < 90
    }
}

// Subtle shadow that swaps sides while flipping
private struct FlipShadow: ViewModifier {
    let isFlipped: Bool
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.18), radius: 12, x: isFlipped ? -4 : 4, y: 8)
    }
}
