import UIKit
import SwiftUI
import AVFoundation

class CameraTextDetectionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var previewView: UIView! // New UIView to hold the preview layer
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCameraPreview()
        setupCameraSession()
    }
    
    func setupCameraPreview() {
        previewView = UIView()
        previewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewView)

        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        previewView.layer.addSublayer(videoPreviewLayer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer.frame = previewView.bounds
    }

    func setupCameraSession() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("Error: Unable to access the camera")
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

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
