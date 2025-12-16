//
//  CaptureFlowView.swift
//  CamShot
//
//  Created by Elizbar Kheladze on 08/12/25.
//

import AVFoundation
import SwiftData
import SwiftUI

struct CaptureFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = CaptureViewModel()
    @StateObject private var camera = CameraModel()
    
    let bgColor = Color.main
    let darkGreen = Color.sub
    let borderGreen = Color.darkerSub
    let accentColor = Color.accent
    let recordRed = Color.recording
    
    var topCameraControls: some View {
        ZStack {
            HStack(spacing: 70) {
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
                        viewModel.zoomLevel = (viewModel.zoomLevel == 0 ? 1 : 0)
                        camera.setZoom(factor: viewModel.zoomLevel == 0 ? 0.5 : 1.0)
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
                        
                        Text(viewModel.zoomLevel == 0 ? "0.5" : "1x")
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
                        
                        Image(systemName: "timer")
                            .font(.system(size: 24))
                            .foregroundColor(accentColor)
                            .rotationEffect(.degrees(camera.isFrontCamera ? 180 : 0))
                            .animation(.spring(), value: camera.isFrontCamera)
                    }
                }
            }
            .padding(.top, 35)
            .padding(.bottom, 60)
        }
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            VStack {
                topCameraControls
                    .opacity(viewModel.capturedImage == nil ? 1 : 0)
                    .allowsHitTesting(viewModel.capturedImage == nil)
                
                ZStack {
                    if let image = viewModel.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 340, height: 340)
                            .blur(radius: viewModel.currentBlur)
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
                .animation(.easeInOut(duration: 0.2), value: viewModel.capturedImage)
                
                Spacer()
                
                ZStack {
                    if viewModel.capturedImage == nil {
                        cameraControls
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        audioControls
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            viewModel.audioManager.onRecordingFinished = { audioData in
                Task {
                    await viewModel.handleRecordingFinished(audioData: audioData, modelContext: modelContext)
                }
            }
        }
        .onChange(of: camera.capturedImage) { _, newImage in
            if let img = newImage {
                withAnimation(.snappy) {
                    viewModel.capturedImage = img
                }
            }
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }
    
    var cameraControls: some View {
        VStack {
            HStack {
                Button { dismiss() } label: {
                    ZStack {
                        Circle()
                            .fill(darkGreen)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .stroke(borderGreen, lineWidth: 3)
                            )
                        
                        Image(systemName: "photo.on.rectangle.angled.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(accentColor)
                    }
                }
                
                Button { camera.takePic() } label: {
                    ZStack {
                        Circle()
                            .fill(.darkerSub)
                            .frame(width: 100, height: 100)
                        Circle()
                            .fill(.main)
                            .frame(width: 85, height: 85)
                        
                        Circle()
                            .fill(.main)
                            .frame(width: 70, height: 70)
                            .shadow(color: .black, radius: 5)
                    }
                }
                .padding(35)
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
        }
    }
    
    var audioControls: some View {
        VStack(spacing: 20) {
            if viewModel.isRecording {
                Text("\(formatTime(viewModel.audioManager.currentTime)) / 00:30")
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
                if !viewModel.isRecording {
                    viewModel.startRecordingProcess()
                } else {
                    if viewModel.canStopRecording {
                        Task {
                            await viewModel.stopRecordingAndSave(modelContext: modelContext)
                        }
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
                    
                    if viewModel.isRecording {
                        if viewModel.canStopRecording {
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
            .disabled(viewModel.isRecording && !viewModel.canStopRecording)
        }
        .frame(height: 180)
    }
    
    private func formatTime(_ time: Double) -> String {
        let seconds = Int(time)
        return String(format: "00:%02d", seconds)
    }
}
