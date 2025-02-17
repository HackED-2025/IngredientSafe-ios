import SwiftUI
import AVFoundation
import Vision
import NaturalLanguage


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

extension String {
    func preprocessText() -> String {
        let lowercased = self.lowercased()
        let cleaned = lowercased.replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
        let stopWords = ["a", "an", "the", "in", "on", "at", "for", "with"]

        let words = cleaned.split(separator: " ").map { String($0) }
        let filteredWords = words.filter { !stopWords.contains($0) }
        let uniqueWords = Array(Set(filteredWords)).joined(separator: " ")
        
        return uniqueWords
    }
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
    var scanForText = true
    
    let similarityThreshold: Double = 0.4
    
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
            print("Started camera")
        } catch { print("Error setting up camera: \(error)") }
    }
    
    func startScanTimer() {
        scanTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.scanForText = true
        }
    }
    
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
                
                let allText = filteredObservations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                if (!allText.isEmpty) {
                    self.searchProductDatabase(for: allText)
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
        let urlString = "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(query)type=Branded&pageSize=5&api_key=\(apiKey ?? "")"
        
        guard let url = URL(string: urlString) else { print("Invalid URL: \(urlString)"); return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { DispatchQueue.main.async { self.waitingForAPIResponse = false }}
            if let error = error { print("API Error: \(error.localizedDescription)"); return }
            
            guard let data = data else { print("No data received from API"); return }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let jsonDict = json as? [String: Any], let foods = jsonDict["foods"] as? [[String: Any]] {
                    let productNames = foods.compactMap { $0["description"] as? String }
                    let bestMatch = self.findBestMatch(for: text, in: productNames)
                    
                    DispatchQueue.main.async {
                        if let match = bestMatch {
                            print("Best match found: \(match)")
                        } else {
                            print("No match found")
                        }
                    }
                } else {
                    print("Invalid JSON structure")
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let (t, u) = (Array(s1), Array(s2))
        let empty = [Int](repeating: 0, count: u.count + 1)
        var last = [Int](0...u.count)
        
        for i in 1...t.count {
            var cur = [i] + empty[1...]
            for j in 1...u.count {
                cur[j] = t[i - 1] == u[j - 1]
                    ? last[j - 1]
                    : Swift.min(last[j], cur[j - 1], last[j - 1]) + 1
            }
            last = cur
        }
        return last.last!
    }

    func tokenSimilarity(_ s1: String, _ s2: String) -> Double {
        // Scale Levenshtein distance into a [0..1] similarity:
        let dist = Double(levenshteinDistance(s1, s2))
        let maxLen = Double(max(s1.count, s2.count))
        // e.g.: 1.0 - (dist / maxLen)
        return 1.0 - (dist / maxLen)
    }

    
    func findBestMatch(for text: String, in productNames: [String]) -> String? {
        // Preprocess the user-detected text
        let processedText = text.preprocessText()
        let textTokens = processedText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        var bestMatch: String? = nil
        var highestScore: Double = 0.0
        
        print("Detected text (processed): \(processedText)")
        
        for product in productNames {
            // Preprocess the product name
            let processedProduct = product.preprocessText()
            let productTokens = processedProduct.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            
            // -- Jaccard similarity on sets of tokens --
            // If you want exact matching only:
            let textSet = Set(textTokens)
            let productSet = Set(productTokens)
            
            let intersectionCount = textSet.intersection(productSet).count
            let unionCount = textSet.union(productSet).count
            // Avoid divide-by-zero
            let jaccardScore = unionCount > 0 ? Double(intersectionCount) / Double(unionCount) : 0.0
            
            
             // -- OPTIONAL: Hybrid approach with token-level fuzzy matching --
//              1. For each token in textTokens, find best fuzzy match in productTokens
//              2. Count a match if similarity > 0.7 (example)
             
            var matchedCount = 0
            for t in textTokens {
              var bestLocal = 0.0
              for p in productTokens {
                  let sim = tokenSimilarity(t, p) // from Levenshtein
                  if sim > bestLocal { bestLocal = sim }
              }
              // If bestLocal > 0.7, consider it a "match"
              if bestLocal > 0.7 { matchedCount += 1 }
            }
            let fuzzyScore = Double(matchedCount) / Double(textTokens.count)
            let finalScore = (jaccardScore + fuzzyScore) / 2.0
            let scoreToUse = finalScore
            
            print("Comparing to: \(processedProduct) | Jaccard score: \(scoreToUse)")
            
            // Track best match
            if scoreToUse > highestScore {
                highestScore = scoreToUse
                bestMatch = product
            }
        }
        
        // Only return the best match if above your threshold
        if highestScore >= similarityThreshold {
            return bestMatch
        } else {
            return nil
        }
    }
}
