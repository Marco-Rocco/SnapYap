//
//  CameraView.swift
//  CamShot
//
//  Created by Elizbar Kheladze on 08/12/25.
//

import SwiftUI
internal import AVFoundation
import Combine

class CameraModel: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var capturedImage: UIImage?
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var isFrontCamera = false
    
    private var output = AVCapturePhotoOutput()
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status { self.setUp() }
            }
        default:
            return
        }
    }
    
    func setUp() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.configureSession(deviceType: .builtInWideAngleCamera, position: .back)
        }
    }
    
    private func configureSession(deviceType: AVCaptureDevice.DeviceType, position: AVCaptureDevice.Position) {
        session.beginConfiguration()
        
        if let currentInput = session.inputs.first {
            session.removeInput(currentInput)
        }
        
        let device = AVCaptureDevice.default(deviceType, for: .video, position: position)
                    ?? AVCaptureDevice.default(for: .video)
        
        if let device = device,
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }
        
        if !session.outputs.contains(output) {
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
        }
        
        session.commitConfiguration()
        
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    func takePic() {
        DispatchQueue.global(qos: .background).async {
            let settings = AVCapturePhotoSettings()
            settings.flashMode = self.flashMode
            self.output.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func toggleFlash() {
        flashMode = (flashMode == .on) ? .off : .on
    }
    
    func flipCamera() {
        isFrontCamera.toggle()
        let position: AVCaptureDevice.Position = isFrontCamera ? .front : .back
        configureSession(deviceType: .builtInWideAngleCamera, position: position)
    }
    
    func setZoom(factor: CGFloat) {
        guard !isFrontCamera else { return }
        
        let deviceType: AVCaptureDevice.DeviceType = (factor < 1.0) ? .builtInUltraWideCamera : .builtInWideAngleCamera
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.configureSession(deviceType: deviceType, position: .back)
        }
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil { return }
        guard let imageData = photo.fileDataRepresentation(),
              let uiImage = UIImage(data: imageData) else { return }
        
        DispatchQueue.main.async {
            if self.isFrontCamera {
                self.capturedImage = UIImage(cgImage: uiImage.cgImage!, scale: uiImage.scale, orientation: .leftMirrored)
            } else {
                self.capturedImage = uiImage
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) -> AutoSizingCameraView {
        let view = AutoSizingCameraView()
        view.previewLayer.session = camera.session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: AutoSizingCameraView, context: Context) {}
    
    class AutoSizingCameraView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
