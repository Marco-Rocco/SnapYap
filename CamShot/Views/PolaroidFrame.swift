//
//  PolaroidFrame.swift
//  CamShot
//
//  Created by Elizbar Kheladze on 08/12/25.
//

import SwiftUI

struct PolaroidFrame: View {
    let image: UIImage
    let audioData: Data?
    var blurAmount: CGFloat = 0
    var showAudioControls: Bool = true
    var enableShadow: Bool = true
    var isCompact: Bool = false
    
    @StateObject private var audioManager = AudioManager()
    @State private var waveformHeights: [CGFloat] = (0..<40).map { _ in CGFloat.random(in: 0.3...1.0) }
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .blur(radius: blurAmount)
                    .clipped()
                    .overlay(Color.black.opacity(blurAmount > 0 ? 0.1 : 0))
            }
            .aspectRatio(1.0, contentMode: .fit)
            .background(Color(white: 0.9))
            .padding(isCompact ? 6 : 8)
            
            ZStack {
                Color.white
                
                if showAudioControls, let data = audioData {
                    HStack(spacing: isCompact ? 8 : 16) {
                        Button {
                            if audioManager.isPlaying {
                                audioManager.stopPlayback()
                            } else {
                                audioManager.startPlayback(data: data)
                            }
                        } label: {
                            Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: isCompact ? 14 : 20))
                                .foregroundColor(.black)
                        }
                        
                        GeometryReader { geometry in
                            let displayBars = isCompact ? Array(waveformHeights.prefix(15)) : waveformHeights
                            let totalBars = displayBars.count
                            let spacing: CGFloat = 2
                            let availableWidth = geometry.size.width - (CGFloat(totalBars) * spacing)
                            let barWidth = max(2, availableWidth / CGFloat(totalBars))
                            
                            HStack(spacing: spacing) {
                                ForEach(0..<totalBars, id: \.self) { index in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(barColor(for: index, total: totalBars))
                                        .frame(height: (isCompact ? 16 : 24) * displayBars[index])
                                        .frame(width: barWidth)
                                        .animation(.easeInOut(duration: 0.1), value: audioManager.currentTime)
                                }
                            }
                            .frame(height: isCompact ? 20 : 30)
                            .frame(maxHeight: .infinity)
                        }
                    }
                    .padding(.horizontal, isCompact ? 8 : 20)
                }
                else if !showAudioControls, audioData != nil {
                    HStack {
                        Spacer()
                        Image(systemName: "waveform")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                            .padding(.trailing, 12)
                    }
                }
            }
            .frame(height: isCompact ? 40 : 60)
        }
        .background(Color.white)
        .shadow(
            color: enableShadow ? .black.opacity(0.2) : .clear,
            radius: enableShadow ? 10 : 0,
            x: 0,
            y: 5
        )
        .onDisappear {
            audioManager.stopPlayback()
        }
    }
    
    private func barColor(for index: Int, total: Int) -> Color {
        guard audioManager.duration > 0 else { return Color.gray.opacity(0.3) }
        
        let progress = audioManager.currentTime / audioManager.duration
        let thresholdIndex = Int(progress * Double(total))
        
        return index <= thresholdIndex ? Color.black : Color.gray.opacity(0.3)
    }
}
