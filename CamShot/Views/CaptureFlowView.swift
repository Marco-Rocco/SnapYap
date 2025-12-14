//
//  CaptureFlowView.swift
//  CamShot
//
//  Created by Elizbar Kheladze on 08/12/25.
//

import SwiftData
import SwiftUI
internal import AVFoundation

struct CaptureFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var capturedImage: UIImage?
    @State private var isRecording = false
    @State private var currentBlur: CGFloat = 30.0
    @State private var zoomLevel: Int = 1
    
    @StateObject private var camera = CameraModel()
    @StateObject private var audioManager = AudioManager()
    
    let bgColor = Color.main
    let darkGreen = Color.sub
    let borderGreen = Color.darkerSub
    let accentColor = Color.accent
    let recordRed = Color.recording
    
    private var canStopRecording: Bool {
        return audioManager.currentTime >= 8.0
    }
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            VStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(capturedImage == nil ? darkGreen : Color.clear)
                    .frame(height: 60)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .opacity(capturedImage == nil ? 1 : 0)
                
                Spacer()
                
                ZStack {
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 340, height: 340)
                            .blur(radius: currentBlur)
                            .clipShape(RoundedRectangle(cornerRadius: 35))
                    } else {
                        CameraPreview(camera: camera)
                            .frame(width: 340, height: 340)
                            .clipShape(RoundedRectangle(cornerRadius: 35))
                            .onAppear { camera.checkPermissions() }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 35)
                        .stroke(Color.white, lineWidth: 6)
                )
                .shadow(radius: 10)
                .animation(.easeInOut(duration: 0.2), value: capturedImage)
                
                Spacer()
                
                ZStack {
                    if capturedImage == nil {
                        cameraControls
                    } else {
                        audioControls
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            audioManager.onRecordingFinished = { audioData in
                finishRecordingAndSave(audioData: audioData)
            }
        }
        .onChange(of: camera.capturedImage) { newImage in
            if let img = newImage {
                withAnimation(.snappy) {
                    self.capturedImage = img
                }
            }
        }
    }
    
    var cameraControls: some View {
        VStack {
            HStack(spacing: 40) {
                Button { camera.toggleFlash() } label: {
                    ZStack {
                        Circle()
                            .fill(darkGreen)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .stroke(borderGreen, lineWidth: 3)
                            )
                        
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 24))
                            .foregroundColor(camera.flashMode == .on ? .yellow : accentColor)
                    }
                }
                
                Button {
                    withAnimation {
                        zoomLevel = (zoomLevel == 0 ? 1 : 0)
                        camera.setZoom(factor: zoomLevel == 0 ? 0.5 : 1.0)
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(darkGreen)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .stroke(borderGreen, lineWidth: 3)
                            )
                        
                        Text(zoomLevel == 0 ? "0.5" : "1x")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(accentColor)
                    }
                }
                
                Button { camera.flipCamera() } label: {
                    ZStack {
                        Circle()
                            .fill(darkGreen)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .stroke(borderGreen, lineWidth: 3)
                            )
                        
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 24))
                            .foregroundColor(accentColor)
                            .rotationEffect(.degrees(camera.isFrontCamera ? 180 : 0))
                            .animation(.spring(), value: camera.isFrontCamera)
                    }
                }
            }
            .padding(.bottom, 20)
            
            Button { camera.takePic() } label: {
                ZStack {
                    Circle()
                        .fill(darkGreen)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(borderGreen, lineWidth: 4)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                    
                    Circle()
                        .fill(darkGreen.opacity(0.8))
                        .frame(width: 70, height: 70)
                }
            }
        }
    }
    
    var audioControls: some View {
        VStack(spacing: 20) {
            if isRecording {
                Text("\(formatTime(audioManager.currentTime)) / 00:30")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .transition(.opacity)
            } else {
                Text("Hold to Record & Reveal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .transition(.opacity)
            }
            
            Button {
                if !isRecording {
                    startRecordingProcess()
                } else {
                    if canStopRecording {
                        let data = audioManager.stopRecording()
                        finishRecordingAndSave(audioData: data)
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(recordRed.opacity(0.4), lineWidth: 4)
                        .frame(width: 90, height: 90)
                    
                    Circle()
                        .fill(recordRed)
                        .frame(width: 70, height: 70)
                        .shadow(radius: 4)
                    
                    if isRecording {
                        if canStopRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(isRecording && !canStopRecording)
        }
        .frame(height: 180)
    }
    
    private func formatTime(_ time: Double) -> String {
        let seconds = Int(time)
        return String(format: "00:%02d", seconds)
    }
    
    private func startRecordingProcess() {
        isRecording = true
        audioManager.startRecording()
        
        withAnimation(.linear(duration: 8.0)) {
            currentBlur = 0
        }
    }
    
    private func finishRecordingAndSave(audioData: Data?) {
        guard let image = capturedImage,
              let audioData = audioData,
              let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let newItem = Item(imageData: imageData, audioData: audioData)
        modelContext.insert(newItem)
        
        isRecording = false
        dismiss()
    }
}
