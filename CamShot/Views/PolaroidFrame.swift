//
//  PolaroidFrame.swift
//  CamShot
//
//  Created by Elizbar Kheladze on 08/12/25.
//

import Accelerate
import AVKit
import SwiftUI

struct PolaroidFrame: View {
    let image: UIImage
    let audioData: Data?
    var blurAmount: CGFloat = 0
    var showAudioControls: Bool = true
    var enableShadow: Bool = true
    var isCompact: Bool = false
    
    @StateObject private var audioManager = AudioManager()
    @State private var samples: [Float] = []
    
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
                            HStack(alignment: .center, spacing: 2) {
                                ForEach(Array(samples.enumerated()), id: \.offset) { index, sample in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(barColor(for: index, total: samples.count))
                                        .frame(width: 2, height: max(CGFloat(sample) * geometry.size.height, 2))
                                }
                            }
                            .frame(height: geometry.size.height)
                            .task(id: geometry.size.width) {
                                await loadAudioSamples(from: data, width: geometry.size.width)
                            }
                        }
                    }
                    .padding(.horizontal, isCompact ? 8 : 20)
                } else if !showAudioControls, audioData != nil {
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
            let duration = Double(audioManager.duration)
            let currentTime = Double(audioManager.currentTime)
            
            guard duration > 0.0 else { return Color.gray.opacity(0.3) }
            
            let progress = currentTime / duration
            let thresholdIndex = Int(progress * Double(total))
            
            return index <= thresholdIndex ? Color.black : Color.gray.opacity(0.3)
        }

    private func loadAudioSamples(from data: Data, width: CGFloat) async {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        do {
            try data.write(to: tempURL)
            let asset = AVURLAsset(url: tempURL)
            
            guard let audioInfo = try SignalProcessingHelper.samples(asset) else { return }
            
            let spacing: CGFloat = 2
            let barWidth: CGFloat = 2
            let count = Int(width / (barWidth + spacing))
            
            let newSamples = try await SignalProcessingHelper.downsample(audioInfo.samples, count: count)
            
            await MainActor.run {
                self.samples = newSamples
            }
            
            try? FileManager.default.removeItem(at: tempURL)
        } catch {
            print("Error loading samples: \(error)")
        }
    }
}
