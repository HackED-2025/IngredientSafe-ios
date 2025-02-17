import SwiftUI
import UIKit
import AVFoundation
import Vision
import NaturalLanguage

// MARK: - The UIViewController subclass
class CameraTextDetectionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // Example properties
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Simple example camera setup
        captureSession.sessionPreset = .high
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput)
        else {
            print("Could not set up camera input.")
            return
        }
        captureSession.addInput(videoInput)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        // Create a video preview layer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.frame = view.bounds
        videoPreviewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(videoPreviewLayer)
        
        // Start capture session
        captureSession.startRunning()
        
        print("CameraTextDetectionViewController set up.")
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        // Handle frames or run OCR
        // e.g., let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    }
}

// MARK: - The SwiftUI wrapper
struct CameraTextDetectionView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> CameraTextDetectionViewController {
        return CameraTextDetectionViewController()
    }
    
    func updateUIViewController(_ uiViewController: CameraTextDetectionViewController, context: Context) {
        // If you need to pass updated data from SwiftUI -> UIViewController, do it here
    }
}
