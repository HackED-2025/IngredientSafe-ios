import SwiftUI
import AVFoundation
import Vision

struct ContentView: View {
    var body: some View {
        CameraTextDetectionView()
            .edgesIgnoringSafeArea(.all)
    }
}

struct CameraTextDetectionView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraTextDetectionViewController {
        return CameraTextDetectionViewController()
    }

    func updateUIViewController(_ uiViewController: CameraTextDetectionViewController, context: Context) {}
}

class CameraTextDetectionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var boundingBoxLayer = CAShapeLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    func setupCamera() {
        captureSession.sessionPreset = .high
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = .resizeAspectFill
            videoPreviewLayer.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer)
            
            boundingBoxLayer.frame = view.bounds
            boundingBoxLayer.strokeColor = UIColor.red.cgColor
            boundingBoxLayer.lineWidth = 2.0
            boundingBoxLayer.fillColor = UIColor.clear.cgColor
            view.layer.addSublayer(boundingBoxLayer)
            
            captureSession.startRunning()
        } catch {
            print("Error setting up camera: \(error)")
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            DispatchQueue.main.async {
                self.drawBoundingBoxes(observations)
                for observation in observations {
                    if let topCandidate = observation.topCandidates(1).first {
                        print("Detected text: \(topCandidate.string)")
                    }
                }
            }
        }

        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }

    func drawBoundingBoxes(_ observations: [VNRecognizedTextObservation]) {
        boundingBoxLayer.sublayers?.forEach { $0.removeFromSuperlayer() } // Clear previous boxes

        for observation in observations {
            let boundingBox = observation.boundingBox
            let convertedBox = self.transformBoundingBox(boundingBox)
            let boxLayer = CAShapeLayer()
            boxLayer.frame = convertedBox
            boxLayer.borderColor = UIColor.red.cgColor
            boxLayer.borderWidth = 2.0
            boundingBoxLayer.addSublayer(boxLayer)
        }
    }

    func transformBoundingBox(_ boundingBox: CGRect) -> CGRect {
        let screenSize = view.bounds.size
        let origin = CGPoint(x: boundingBox.minX * screenSize.width, y: (1 - boundingBox.maxY) * screenSize.height)
        let size = CGSize(width: boundingBox.width * screenSize.width, height: boundingBox.height * screenSize.height)
        return CGRect(origin: origin, size: size)
    }
}
