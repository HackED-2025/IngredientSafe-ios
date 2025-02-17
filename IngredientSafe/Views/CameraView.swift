import SwiftUI
import UIKit
import AVFoundation
import Vision
import NaturalLanguage

// MARK: - The SwiftUI wrapper
struct CameraTextDetectionView: UIViewControllerRepresentable {
    /// Called when the OpenAI analysis is completed, passing the final text to SwiftUI
    var onAnalysisCompleted: (String, String) -> Void
    
    /// A binding so SwiftUI can request the controller to reset scanning
    @Binding var resetRequested: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> CameraTextDetectionViewController {
        let vc = CameraTextDetectionViewController()
        
        // Provide the callback so the VC can call back up
        vc.onAnalysisCompleted = { productName, rawGPTText in
            onAnalysisCompleted(productName, rawGPTText)
        }
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CameraTextDetectionViewController,
                                context: Context) {
        // If SwiftUI sets resetRequested = true, call resetScan() in the VC
        if resetRequested {
            uiViewController.resetScan()
        }
    }
    
    // Acts as a bridge if needed
    class Coordinator: NSObject {
        var parent: CameraTextDetectionView
        init(_ parent: CameraTextDetectionView) {
            self.parent = parent
        }
    }
}

// MARK: - The main UIViewController with OCR + API logic
class CameraTextDetectionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // If you want to pass the final OpenAI text to SwiftUI
    var onAnalysisCompleted: ((String, String) -> Void)?
    
    // MARK: - Product info
    private var currentProductName: String?
    
    // MARK: - Camera Session
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var previewView: UIView!
    
    // MARK: - Overlay & Bounding Boxes
    var boundingBoxLayer = CAShapeLayer()
    var overlayLayer = CAShapeLayer()
    
    // Adjust these to define the region you want to scan
    let scanX: CGFloat = 0.25
    let scanY: CGFloat = 0.25
    let scanWidth: CGFloat = 0.5
    let scanHeight: CGFloat = 0.5
    
    // MARK: - API Keys
    var usdaApiKey: String!
    var openAiApiKey: String!
    
    // MARK: - Scanning/State
    var waitingForAPIResponse: Bool = false
    var scanForText = true
    private var hasFoundProduct = false
    
    var scanTimer: Timer?
    
    let similarityThreshold: Double = 0.3
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usdaApiKey = Bundle.main.object(forInfoDictionaryKey: "USDA_API_KEY") as? String
        openAiApiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
        
        setupCameraPreview()
        setupCameraSession()
        addOverlayLayer()
        startScanTimer()
    }
    
    /// Reset scanning if the user dismisses the product overlay
    func resetScan() {
        self.hasFoundProduct = false
        self.waitingForAPIResponse = false
        // Optional: Clear bounding boxes, or restart the session if you prefer
        DispatchQueue.main.async {
            self.boundingBoxLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        }
        print("Scanning has been reset.")
    }
    
    // MARK: - Preview Setup
    func setupCameraPreview() {
        previewView = UIView(frame: .zero)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewView)
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = previewView.bounds
        boundingBoxLayer.frame = previewView.bounds
    }
    
    // MARK: - Camera Session
    func setupCameraSession() {
        captureSession.sessionPreset = .high
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                        for: .video,
                                                        position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice)
        else {
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
        
        // Create/attach preview layer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        previewView.layer.addSublayer(videoPreviewLayer)
        
        // Prepare boundingBox layer for recognized text
        boundingBoxLayer.strokeColor = UIColor.red.cgColor
        boundingBoxLayer.lineWidth = 2.0
        boundingBoxLayer.fillColor = UIColor.clear.cgColor
        previewView.layer.addSublayer(boundingBoxLayer)
        
        // Start capture session
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    func startScanTimer() {
        scanTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.scanForText = true
        }
    }
    
    func addOverlayLayer() {
        let path = UIBezierPath(rect: view.bounds)
        let centerRect = CGRect(
            x: view.bounds.width  * scanX,
            y: view.bounds.height * scanY,
            width: view.bounds.width  * scanWidth,
            height: view.bounds.height * scanHeight
        )
        let clearPath = UIBezierPath(rect: centerRect)
        path.append(clearPath)
        path.usesEvenOddFillRule = true
        
        overlayLayer.path = path.cgPath
        overlayLayer.fillRule = .evenOdd
        overlayLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        previewView.layer.addSublayer(overlayLayer)
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        guard scanForText else { return }
        guard !waitingForAPIResponse else { return }
        
        // Only scan once every timer tick
        scanForText = false
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  error == nil else { return }
            
            DispatchQueue.main.async {
                let centerRect = CGRect(x: self.scanX, y: self.scanY,
                                        width: self.scanWidth, height: self.scanHeight)
                let filteredObs = observations.filter { centerRect.intersects($0.boundingBox) }
                
                self.drawBoundingBoxes(filteredObs)
                
                let allText = filteredObs
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: " ")
                
                if !allText.isEmpty && !self.hasFoundProduct {
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
        
        for obs in observations {
            let bb = obs.boundingBox
            let converted = transformBoundingBox(bb)
            let boxLayer = CAShapeLayer()
            let path = UIBezierPath(rect: converted)
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
            y: 1.0 - boundingBox.origin.y - boundingBox.height,
            width: boundingBox.width,
            height: boundingBox.height
        )
        return videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: metadataRect)
    }
    
    // MARK: - 1) USDA Search
    func searchProductDatabase(for rawText: String) {
        waitingForAPIResponse = true
        
        let query = rawText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(query)&pageSize=5&api_key=\(usdaApiKey ?? "")"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            waitingForAPIResponse = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { DispatchQueue.main.async { self.waitingForAPIResponse = false } }
            
            if let error = error {
                print("API Error: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("No data received from USDA")
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                guard
                    let jsonDict = json as? [String: Any],
                    let foods = jsonDict["foods"] as? [[String: Any]]
                else {
                    print("USDA returned invalid JSON: \(json)")
                    return
                }
                
                let descriptions = foods.compactMap { $0["description"] as? String }
                let bestMatch = self.findBestMatch(for: rawText, in: descriptions)
                
                DispatchQueue.main.async {
                    if let match = bestMatch,
                       let matchedFood = foods.first(where: { ($0["description"] as? String) == match }),
                       let foodId = matchedFood["fdcId"] as? Int {
                        
                        self.hasFoundProduct = true
                        self.fetchNutritionDetails(for: String(foodId), productName: match)
                    } else {
                        print("No suitable match found for text: \(rawText)")
                    }
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // MARK: - 2) USDA Nutrition Details
    func fetchNutritionDetails(for foodId: String, productName: String) {
        self.currentProductName = productName
        let detailUrlString = "https://api.nal.usda.gov/fdc/v1/food/\(foodId)?api_key=\(usdaApiKey ?? "")"
        guard let url = URL(string: detailUrlString) else {
            print("Invalid detail URL for USDA nutrition details")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching nutrition details: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("No data for nutrition details")
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                guard let nutritionData = json as? [String: Any] else {
                    print("Invalid JSON structure for nutrition details.")
                    return
                }
                
                var labelNutrients: [String: Any] = [:]
                if let ln = nutritionData["labelNutrients"] as? [String: Any] {
                    labelNutrients = ln
                }
                let ingredients = nutritionData["ingredients"] as? String ?? "No ingredients info"
                
                let extractedData = self.extractNutritionAndIngredients(nutrients: labelNutrients,
                                                                        ingredients: ingredients)
                self.analyzeWithOpenAI(nutritionData: extractedData, productName: productName)
                
            } catch {
                print("Error parsing nutrition JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // MARK: - 3) OpenAI Analysis
    func analyzeWithOpenAI(nutritionData: [String: Any], productName: String) {
        guard let openAiApiKey = openAiApiKey, !openAiApiKey.isEmpty else {
            print("OpenAI API key is missing; cannot proceed.")
            return
        }
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAiApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Example prompt
        let preferences = "User dietary preferences: Celiacs Disease, low-sugar, no dairy."
        let prompt = """
        I have the following dietary restrictions: {user selected conditions}. Rank the product on how safe or nutritious it is for me to eat.
        Product: \(productName)
        Nutrition: \(nutritionData)
        Preferences: \(preferences)
        Return an integer from 1-10 on a single line ranking the product safety, followed by a newline, and then a short bulleted list describing concisely on each bullet what ingredient/macronutrient caused the score to be good/bad. Order these bullets from most critical to least critical.
        """
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are helping me decide if a product is safe for my diet."],
                ["role": "user",   "content": prompt]
            ],
            "max_tokens": 200
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("OpenAI API error: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("No data from OpenAI")
                return
            }
            do {
                // Try decoding to our struct
                let responseModel = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                
                // The text we want is usually in the first choice -> message -> content
                if let content = responseModel.choices.first?.message.content {
                    DispatchQueue.main.async {
                        // pass just the content back to SwiftUI
                        self.onAnalysisCompleted?(productName, content)
                    }
                } else {
                    // If there's no content, fallback
                    DispatchQueue.main.async {
                        self.onAnalysisCompleted?(productName, "No content found.")
                    }
                }
            } catch {
                print("Error decoding OpenAI JSON: \(error)")
                // Fallback: pass raw text so you can debug
                let rawGPTText = String(data: data, encoding: .utf8) ?? "No response"
                DispatchQueue.main.async {
                    self.onAnalysisCompleted?(productName, rawGPTText)
                }
            }
        }.resume()
    }
    
    struct OpenAIResponse: Decodable {
        let choices: [Choice]
        
        struct Choice: Decodable {
            let message: Message
        }
        
        struct Message: Decodable {
            let role: String
            let content: String
        }
    }
    
    
    // MARK: - Helper: Extract Nutrition & Ingredients
    func extractNutritionAndIngredients(nutrients: [String: Any], ingredients: String) -> [String: Any] {
        let macronutrients = ["calories", "protein", "fat", "carbohydrates", "fiber", "sugars", "sodium"]
        var extracted: [String: Any] = [:]
        
        for key in macronutrients {
            if let nested = nutrients[key] as? [String: Any],
               let value = nested["value"] {
                extracted[key] = value
            }
        }
        extracted["ingredients"] = ingredients
        return extracted
    }
    
    // MARK: - Helper: Find Best Match
    func findBestMatch(for text: String, in productNames: [String]) -> String? {
        let processedText = text.preprocessText()
        let textTokens = processedText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        var bestMatch: String? = nil
        var highestScore: Double = 0.0
        
        for product in productNames {
            let processedProduct = product.preprocessText()
            let productTokens = processedProduct.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            
            // Jaccard similarity
            let textSet = Set(textTokens)
            let productSet = Set(productTokens)
            let intersectionCount = textSet.intersection(productSet).count
            let unionCount = textSet.union(productSet).count
            let jaccardScore = unionCount > 0 ? Double(intersectionCount) / Double(unionCount) : 0.0
            
            // Fuzzy token match
            var matchedCount = 0
            for t in textTokens {
                var bestLocal = 0.0
                for p in productTokens {
                    let sim = tokenSimilarity(t, p)
                    if sim > bestLocal { bestLocal = sim }
                }
                if bestLocal > 0.7 { matchedCount += 1 }
            }
            let fuzzyScore = Double(matchedCount) / Double(textTokens.count)
            
            let finalScore = (jaccardScore + fuzzyScore) / 2.0
            if finalScore > highestScore {
                highestScore = finalScore
                bestMatch = product
            }
        }
        
        if highestScore >= similarityThreshold {
            return bestMatch
        } else {
            return nil
        }
    }
    
    // MARK: - Fuzzy (Levenshtein) Similarity
    func tokenSimilarity(_ s1: String, _ s2: String) -> Double {
        let dist = Double(levenshteinDistance(s1, s2))
        let maxLen = Double(max(s1.count, s2.count))
        return 1.0 - (dist / maxLen)
    }
    
    func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let (t, u) = (Array(s1), Array(s2))
        let empty = [Int](repeating: 0, count: u.count + 1)
        var last = [Int](0...u.count)
        for i in 1...t.count {
            var cur = [i] + empty[1...]
            for j in 1...u.count {
                if t[i - 1] == u[j - 1] {
                    cur[j] = last[j - 1]
                } else {
                    cur[j] = Swift.min(last[j], cur[j - 1], last[j - 1]) + 1
                }
            }
            last = cur
        }
        return last.last!
    }
}

// MARK: - Extension: Preprocess recognized text
extension String {
    func preprocessText() -> String {
        let lowercased = self.lowercased()
        let cleaned = lowercased.replacingOccurrences(of: "[^a-z0-9 ]",
                                                      with: "",
                                                      options: .regularExpression)
        let stopWords = ["a", "an", "the", "in", "on", "at", "for", "with"]
        let words = cleaned.split(separator: " ").map { String($0) }
        let filteredWords = words.filter { !stopWords.contains($0) }
        let uniqueWords = Array(Set(filteredWords)).joined(separator: " ")
        return uniqueWords
    }
}
