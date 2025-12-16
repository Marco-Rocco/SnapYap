//
//  PolaroidFrame.swift
//  CamShot
//
//  Created by Elizbar Kheladze on 08/12/25.
//

import AVKit
import SwiftUI

struct PolaroidFrame: View {
    let image: UIImage
    let audioData: Data?
    let waveform: [Float]?
    var blurAmount: CGFloat = 0
    var showAudioControls: Bool = true
    var enableShadow: Bool = true
    var isCompact: Bool = false
    var onWaveformGenerated: (([Float]) -> Void)? = nil
    
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
                            let barWidth: CGFloat = 2
                            let spacing: CGFloat = 2
                            let availableWidth = geometry.size.width
                            let targetCount = Int(availableWidth / (barWidth + spacing))
                            let displaySamples = reSample(samples, targetCount: max(targetCount, 1))
                            
                            HStack(alignment: .center, spacing: spacing) {
                                ForEach(Array(displaySamples.enumerated()), id: \.offset) { index, sample in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(barColor(for: index, total: displaySamples.count))
                                        .frame(width: barWidth, height: max(CGFloat(sample) * geometry.size.height, 5))
                                }
                            }
                            .frame(height: geometry.size.height)
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
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onAppear {
            if let samples = waveform {
                self.samples = samples
            } else if let audioData = audioData, !audioData.isEmpty {
                Task {
                    await generateWaveform(from: audioData)
                }
            }
        }
    }
    
    private func reSample(_ input: [Float], targetCount: Int) -> [Float] {
        guard input.count > 0, targetCount > 0 else { return [] }
        if input.count == targetCount { return input }
        
        var output = [Float](repeating: 0, count: targetCount)
        let step = Double(input.count) / Double(targetCount)
        
        for i in 0..<targetCount {
            let start = Int(Double(i) * step)
            let end = min(Int(Double(i + 1) * step), input.count)
            
            if start < end {
                var maxVal: Float = 0
                for j in start..<end {
                    maxVal = max(maxVal, input[j])
                }
                output[i] = maxVal
            } else {
                if start < input.count {
                    output[i] = input[start]
                }
            }
        }
        return output
    }
    
    private func barColor(for index: Int, total: Int) -> Color {
        let duration = Double(audioManager.duration)
        let currentTime = Double(audioManager.currentTime)
            
        guard duration > 0.0 else { return Color.gray.opacity(0.3) }
            
        let progress = currentTime / duration
        let thresholdIndex = Int(progress * Double(total))
            
        return index <= thresholdIndex ? Color.black : Color.gray.opacity(0.3)
    }

    private func generateWaveform(from data: Data) async {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        do {
            try data.write(to: tempURL)
            let asset = AVURLAsset(url: tempURL)
            
            guard let audioInfo = try SignalProcessingHelper.samples(asset) else { return }
            
            let targetCount = 100
            let newSamples = try await SignalProcessingHelper.downsample(audioInfo.samples, count: targetCount)
            
            await MainActor.run {
                self.samples = newSamples
                self.onWaveformGenerated?(newSamples)
            }
            
            try? FileManager.default.removeItem(at: tempURL)
        } catch {
            print("Error generating waveform: \(error)")
        }
    }
}
