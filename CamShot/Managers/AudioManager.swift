//
//  AudioManager.swift
//  CamShot
//
//  Created by Elizbar Kheladze on 08/12/25.
//

import AVFoundation
import Foundation
import Combine

class AudioManager: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var duration: TimeInterval = 0.0
    @Published var currentTime: TimeInterval = 0.0
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    override init() {
        super.init()
        setupSession()
    }
    
    deinit {
        stopPlayback()
        stopRecording()
    }
    
    private func setupSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func startRecording() {
        let fileName = FileManager.default.temporaryDirectory.appendingPathComponent("temp_recording.m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileName, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func stopRecording() -> Data? {
        audioRecorder?.stop()
        isRecording = false
        audioRecorder = nil
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("temp_recording.m4a")
        return try? Data(contentsOf: url)
    }
    
    func startPlayback(data: Data) {
        stopPlayback()
        
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            duration = audioPlayer?.duration ?? 0.0
            audioPlayer?.play()
            isPlaying = true
            startTimer()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        stopTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentTime = self.audioPlayer?.currentTime ?? 0.0
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        currentTime = 0.0
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopTimer()
    }
}
