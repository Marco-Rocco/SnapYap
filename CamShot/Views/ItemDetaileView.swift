//
//  ItemDetaileView.swift
//  CamShot
//
//  Created by Elizbar Kheladze on 08/12/25.
//

import SwiftData
import SwiftUI

struct ItemDetailView: View {
    @Query(sort: \Item.timestamp, order: .reverse) private var items: [Item]
    @State var selectedID: UUID
    
    let thumbnailSize: CGFloat = 40
    let thumbnailSpacing: CGFloat = 8
    
    var body: some View {
        ZStack {
            Color.main.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                TabView(selection: $selectedID) {
                    ForEach(items) { item in
                        if let uiImage = UIImage(data: item.imageData) {
                            VStack {
                                Spacer()
                                PolaroidFrame(
                                    image: uiImage,
                                    audioData: item.audioData,
                                    blurAmount: 0,
                                    showAudioControls: true,
                                    enableShadow: false
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
                                    .frame(width: geo.size.width / 2 - thumbnailSize / 2 - thumbnailSpacing)
                                
                                ForEach(items) { item in
                                    if let uiImage = UIImage(data: item.imageData) {
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedID = item.id
                                            }
                                        } label: {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: thumbnailSize, height: thumbnailSize)
                                                .clipped()
                                                .opacity(selectedID == item.id ? 1.0 : 0.5)
                                                .border(Color.white, width: selectedID == item.id ? 2 : 0)
                                        }
                                        .id(item.id)
                                    }
                                }
                                
                                Spacer()
                                    .frame(width: geo.size.width / 2 - thumbnailSize / 2 - thumbnailSpacing)
                            }
                            .padding(.bottom, 20)
                        }
                        .frame(height: 60)
                        .onChange(of: selectedID) { _, newID in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(newID, anchor: .center)
                            }
                        }
                        .onAppear {
                            proxy.scrollTo(selectedID, anchor: .center)
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
