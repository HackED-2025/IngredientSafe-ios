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
    var overlayLayer = CAShapeLayer()
    
    let scanX = 0.25
    let scanY = 0.25
    let scanWidth = 0.5
    let scanHeight = 0.5
    
    var apiKey: String!
    var waitingForAPIResponse: Bool = false
    
    
    var scanTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        startScanTimer()
        apiKey = Bundle.main.object(forInfoDictionaryKey: "USDA_API_KEY") as? String

    }

    func setupCamera() {
        captureSession.sessionPreset = .high
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) { captureSession.addInput(videoInput) }
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            if captureSession.canAddOutput(videoOutput) { captureSession.addOutput(videoOutput) }

            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = .resizeAspectFill
            videoPreviewLayer.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer)

            boundingBoxLayer.frame = view.bounds
            boundingBoxLayer.strokeColor = UIColor.red.cgColor
            boundingBoxLayer.lineWidth = 2.0
            boundingBoxLayer.fillColor = UIColor.clear.cgColor
            view.layer.addSublayer(boundingBoxLayer)

            addOverlayLayer()
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        } catch { print("Error setting up camera: \(error)") }
    }
    
    func startScanTimer() {
        scanTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.scanForText = true
        }
    }
    
    var scanForText = false
    
    func addOverlayLayer() {
        let path = UIBezierPath(rect: view.bounds)
        let centerRect = CGRect(x: view.bounds.width * scanX, y: view.bounds.height * scanY, width: view.bounds.width * scanWidth, height: view.bounds.height * scanHeight)
        let clearPath = UIBezierPath(rect: centerRect)
        path.append(clearPath)
        path.usesEvenOddFillRule = true

        overlayLayer.path = path.cgPath
        overlayLayer.fillRule = .evenOdd
        overlayLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        view.layer.addSublayer(overlayLayer)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard scanForText else { return } // Skip processing if timer not triggered yet
        guard !waitingForAPIResponse else { return }
        scanForText = false // Reset after triggering
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            DispatchQueue.main.async {
                let centerRect = CGRect(x: self.scanX, y: self.scanY, width: self.scanWidth, height: self.scanHeight)
                let filteredObservations = observations.filter { centerRect.intersects($0.boundingBox) }
                self.drawBoundingBoxes(filteredObservations)
                for observation in filteredObservations {
                    if let topCandidate = observation.topCandidates(1).first {
                        let scannedText = topCandidate.string
                        print("Detected text: \(scannedText)")
                        self.searchProductDatabase(for: scannedText)
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
        boundingBoxLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        for observation in observations {
            let boundingBox = observation.boundingBox
            let convertedBox = self.transformBoundingBox(boundingBox)
            let boxLayer = CAShapeLayer()
            let path = UIBezierPath(rect: convertedBox)
            boxLayer.path = path.cgPath
            boxLayer.strokeColor = UIColor.red.cgColor
            boxLayer.lineWidth = 2.0
            boxLayer.fillColor = UIColor.clear.cgColor
            boundingBoxLayer.addSublayer(boxLayer)
        }
    }

    func transformBoundingBox(_ boundingBox: CGRect) -> CGRect {
        let metadataRect = CGRect(
            x: boundingBox.origin.x,
            y: 1 - boundingBox.origin.y - boundingBox.height,
            width: boundingBox.width,
            height: boundingBox.height
        )
        return videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: metadataRect)
    }

    func searchProductDatabase(for text: String) {
        waitingForAPIResponse = true
        let query = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(query)&pageSize=5&api_key=\(apiKey ?? "")"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { DispatchQueue.main.async { self.waitingForAPIResponse = false }}
            if let error = error {
                print("API Error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("HTTP Response Headers: \(httpResponse.allHeaderFields)")
                }
            }
            
            guard let data = data else {
                print("No data received from API")
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                
                if let jsonDict = json as? [String: Any] {
                    if let foods = jsonDict["foods"] as? [[String: Any]] {
                        var resultString = ""
                        for food in foods {
                            if let description = food["description"] as? String {
                                resultString += "- \(description)\n"
                            }
                        }
                        DispatchQueue.main.async {
                            print("API Call results for \(text):\n\(resultString)")
                        }
                    } else {
                        print("Missing or invalid 'foods' key in JSON: \(jsonDict)")
                    }
                } else {
                    print("JSON is not a dictionary: \(json)")
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)\nData received: \(String(data: data, encoding: .utf8) ?? "Unable to decode data")")
            }
        }.resume()
    }
}
