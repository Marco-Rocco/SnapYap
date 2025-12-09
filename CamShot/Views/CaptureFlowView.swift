//
//  CaptureFlowView.swift
//  CamShot
//
//  Created by Elizbar Kheladze on 08/12/25.
//

import SwiftUI
import SwiftData

struct CaptureFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var capturedImage: UIImage?
    @State private var showCamera = true
    @State private var isRecording = false
    @State private var currentBlur: CGFloat = 30.0
    @StateObject private var audioManager = AudioManager()
    
    var body: some View {
        VStack {
            if let image = capturedImage {
                Spacer()
                
                PolaroidFrame(
                    image: image,
                    audioData: nil,
                    blurAmount: currentBlur,
                    showAudioControls: false
                )
                .padding(.horizontal, 40)
                
                Spacer()
                
                VStack(spacing: 24) {
                    if !isRecording {
                        Text("Hold to Record & Reveal")
                            .font(.callout)
                            .foregroundColor(.gray)
                            .transition(.opacity)
                    } else {
                        Text("Revealing...")
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                            .transition(.opacity)
                    }
                    
                    Button {
                        if isRecording {
                            finishRecordingAndSave()
                        } else {
                            startRecordingProcess()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .strokeBorder(isRecording ? Color.red : Color.black, lineWidth: 3)
                                .frame(width: 74, height: 74)
                            
                            Circle()
                                .fill(isRecording ? Color.red : Color.black)
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Group {
                                        if isRecording {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.white)
                                                .frame(width: 28, height: 28)
                                        } else {
                                            Image(systemName: "mic.fill")
                                                .foregroundColor(.white)
                                                .font(.title2)
                                        }
                                    }
                                )
                        }
                    }
                }
                .padding(.bottom, 50)
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .background(Color(white: 0.95))
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(image: $capturedImage)
        }
        .onChange(of: capturedImage) { _, newValue in
            if newValue == nil {
                dismiss()
            }
        }
    }
    
    private func startRecordingProcess() {
        isRecording = true
        audioManager.startRecording()
        
        withAnimation(.linear(duration: 8.0)) {
            currentBlur = 0
        }
    }
    
    private func finishRecordingAndSave() {
        guard let imageData = capturedImage?.jpegData(compressionQuality: 0.8),
              let audioData = audioManager.stopRecording() else { return }
        
        isRecording = false
        
        let newItem = Item(imageData: imageData, audioData: audioData)
        modelContext.insert(newItem)
        
        
//        UIImageWriteToSavedPhotosAlbum(UIImage(data: imageData)!, nil, nil, nil)
        
        dismiss()
    }
}
