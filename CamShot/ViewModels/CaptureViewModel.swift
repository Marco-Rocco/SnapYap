//
//  CaptureViewModel.swift
//  CamShot
//
//  Created by Adriano Oliviero on 16/12/25.
//

import AVFoundation
import Combine
import SwiftData
import SwiftUI

@MainActor
class CaptureViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isRecording = false
    @Published var currentBlur: CGFloat = 30.0
    @Published var zoomLevel: Int = 1
    @Published var shouldDismiss = false

    let audioManager = AudioManager()

    var canStopRecording: Bool {
        return audioManager.currentTime >= 8.0
    }

    func startRecordingProcess() {
        isRecording = true
        audioManager.startRecording()

        withAnimation(.linear(duration: 8.0)) {
            currentBlur = 0
        }
    }

    func stopRecordingAndSave(modelContext: ModelContext) async {
        let audioData = audioManager.stopRecording()
        await saveItem(audioData: audioData, modelContext: modelContext)
    }

    func handleRecordingFinished(audioData: Data?, modelContext: ModelContext) async {
        await saveItem(audioData: audioData, modelContext: modelContext)
    }

    private func saveItem(audioData: Data?, modelContext: ModelContext) async {
        guard let image = capturedImage,
              let audioData = audioData,
              let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        var waveformSamples: [Float]?

        let tempAudioURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        do {
            try audioData.write(to: tempAudioURL)
            let asset = AVURLAsset(url: tempAudioURL)

            if let audioInfo = try SignalProcessingHelper.samples(asset) {
                let targetWaveformBarCount = 100
                waveformSamples = try await SignalProcessingHelper.downsample(audioInfo.samples, count: targetWaveformBarCount)
            }
        } catch {
            print("Error generating waveform samples: \(error)")
        }

        try? FileManager.default.removeItem(at: tempAudioURL)

        let newItem = Item(imageData: imageData, audioData: audioData, waveform: waveformSamples)
        modelContext.insert(newItem)

        isRecording = false
        shouldDismiss = true
    }
}
