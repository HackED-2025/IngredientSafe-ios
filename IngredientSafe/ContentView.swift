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
    // MARK: - Camera / UI Layers
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var boundingBoxLayer = CAShapeLayer()
    var overlayLayer = CAShapeLayer()
    
    let scanX = 0.25
    let scanY = 0.25
    let scanWidth = 0.5
    let scanHeight = 0.5
    
    var usdaApiKey: String!
    var openAiApiKey: String!
    
    var waitingForAPIResponse: Bool = false
    var scanForText = true
    var scanTimer: Timer?
    
    let similarityThreshold: Double = 0.3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        startScanTimer()
        usdaApiKey = Bundle.main.object(forInfoDictionaryKey: "USDA_API_KEY") as? String
        openAiApiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
    }
    
    // MARK: - Camera Setup
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
            
            addOverlayLayer()
            
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
            print("Started camera")
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    func startScanTimer() {
        // Re-scan once per second
        scanTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.scanForText = true
        }
    }
    
    func addOverlayLayer() {
        let path = UIBezierPath(rect: view.bounds)
        let centerRect = CGRect(
            x: view.bounds.width * scanX,
            y: view.bounds.height * scanY,
            width: view.bounds.width * scanWidth,
            height: view.bounds.height * scanHeight
        )
        let clearPath = UIBezierPath(rect: centerRect)
        path.append(clearPath)
        path.usesEvenOddFillRule = true
        
        overlayLayer.path = path.cgPath
        overlayLayer.fillRule = .evenOdd
        overlayLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        view.layer.addSublayer(overlayLayer)
    }
    
    // MARK: - Capture Delegate (OCR)
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard scanForText else { return }
        guard !waitingForAPIResponse else { return }
        
        scanForText = false // reset until next timer tick
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            DispatchQueue.main.async {
                let centerRect = CGRect(
                    x: self.scanX,
                    y: self.scanY,
                    width: self.scanWidth,
                    height: self.scanHeight
                )
                let filteredObservations = observations.filter {
                    centerRect.intersects($0.boundingBox)
                }
                self.drawBoundingBoxes(filteredObservations)
                
                // Combine all recognized text in bounding box region
                let allText = filteredObservations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: " ")
                
                if !allText.isEmpty {
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
            let convertedBox = transformBoundingBox(boundingBox)
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
    
    // MARK: - Pipeline Step 1: Search USDA
    func searchProductDatabase(for text: String) {
        waitingForAPIResponse = true
        let query = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(query)&pageSize=10&api_key=\(usdaApiKey ?? "")"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer {
                DispatchQueue.main.async {
                    self.waitingForAPIResponse = false
                }
            }
            if let error = error {
                print("API Error: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("No data received from API")
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let jsonDict = json as? [String: Any],
                   let foods = jsonDict["foods"] as? [[String: Any]] {
                    
                    // We'll gather all descriptions
                    let descriptions = foods.compactMap { $0["description"] as? String }
                    // Find the best match among them
                    let bestMatch = self.findBestMatch(for: text, in: descriptions)
                    
                    DispatchQueue.main.async {
                        if let match = bestMatch {
                            print("Best match found: \(match)")
                            
                            // Now find the actual record so we can get the FDC ID
                            if let matchedFood = foods.first(where: { ($0["description"] as? String) == match }),
                               let foodId = matchedFood["fdcId"] as? Int {
                                
                                // 2nd step: get the detailed nutrition
                                self.fetchNutritionDetails(for: String(foodId), productName: match)
                            } else {
                                print("Could not find FDC ID for matched product")
                            }
                        } else {
                            print("No match found for text: \(text)")
                        }
                    }
                } else {
                    print("Invalid JSON structure from search endpoint")
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // MARK: - Pipeline Step 2: Fetch Detailed Nutrition
    func fetchNutritionDetails(for foodId: String, productName: String) {
        let detailUrlString = "https://api.nal.usda.gov/fdc/v1/food/\(foodId)?api_key=\(usdaApiKey ?? "")"
        guard let url = URL(string: detailUrlString) else {
            print("Invalid detail URL for nutrition details")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching nutrition details: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received for nutrition details")
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                
                guard let nutritionData = json as? [String: Any] else {
                    print("Invalid JSON structure for nutrition details")
                    return
                }
                
                // If you're dealing with a BrandedFoodItem, it may have 'labelNutrients' or 'foodNutrients' etc.
                // We'll try to extract from labelNutrients or from the general array. Adjust as needed based on USDA doc.
                
                // Some items have "labelNutrients" (dictionary), some have "foodNutrients" (array).
                var labelNutrients: [String: Any] = [:]
                if let ln = nutritionData["labelNutrients"] as? [String: Any] {
                    labelNutrients = ln
                }
                
                // Ingredients might be under "ingredients"
                let ingredients = nutritionData["ingredients"] as? String ?? "No ingredients info"
                
                // Prepare data to feed to OpenAI
                let extractedData = self.extractNutritionAndIngredients(nutrients: labelNutrients, ingredients: ingredients)
                
                // Now pass it to OpenAI
                self.analyzeWithOpenAI(nutritionData: extractedData, productName: productName)
                
            } catch {
                print("Error parsing nutrition details JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // MARK: - Pipeline Step 3: Analyze with OpenAI
    func analyzeWithOpenAI(nutritionData: [String: Any], productName: String) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAiApiKey ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let preferences = "User dietary preferences: Celiacs Disease, low-sugar, no dairy."
        let prompt = """
        I have the following dietary restrictions: {user selected conditions}. Rank the product on how safe or nutritious it is for me to eat.
        Product: \(productName)
        Nutrition: \(nutritionData)
        Preferences: \(preferences)
        Return an integer from 1-10 on a single line ranking the product safety, followed by a newline, and then an ordered concise bulleted list for each ingredient/macronutrient that is good or bad according to my restrictions. This list should be ranked from most harmful to most beneficial.       
        """
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "system",
                    "content": "You are helping me decide on whether a product will be good for my health."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 200
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("OpenAI API Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data from OpenAI")
                return
            }
            
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) {
                print("OpenAI Analysis Result: \(jsonResponse)")
            } else {
                print("Failed to parse OpenAI response")
                if let rawStr = String(data: data, encoding: .utf8) {
                    print("Raw response: \(rawStr)")
                }
            }
        }.resume()
    }
    
    // MARK: - Helper: Nutrition & Ingredients
    func extractNutritionAndIngredients(nutrients: [String: Any], ingredients: String) -> [String: Any] {
        // Common macronutrients you might care about:
        let macronutrients = ["calories", "protein", "fat", "carbohydrates", "fiber", "sugars", "sodium"]
        var extracted: [String: Any] = [:]
        
        // If labelNutrients is structured as: "calories": ["value": 100], etc.
        for key in macronutrients {
            if let nested = nutrients[key] as? [String: Any],
               let value = nested["value"] {
                extracted[key] = value
            }
        }
        
        extracted["ingredients"] = ingredients
        return extracted
    }
    
    // MARK: - Local Similarity (Jaccard + Fuzzy)
    func findBestMatch(for text: String, in productNames: [String]) -> String? {
        let processedText = text.preprocessText()
        let textTokens = processedText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        var bestMatch: String? = nil
        var highestScore: Double = 0.0
        
        print("Detected text (processed): \(processedText)")
        
        for product in productNames {
            let processedProduct = product.preprocessText()
            let productTokens = processedProduct.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            
            // Jaccard similarity
            let textSet = Set(textTokens)
            let productSet = Set(productTokens)
            let intersectionCount = textSet.intersection(productSet).count
            let unionCount = textSet.union(productSet).count
            let jaccardScore = unionCount > 0 ? Double(intersectionCount) / Double(unionCount) : 0.0
            
            // Fuzzy token match (Levenshtein)
            var matchedCount = 0
            for t in textTokens {
                var bestLocal = 0.0
                for p in productTokens {
                    let sim = tokenSimilarity(t, p)
                    if sim > bestLocal {
                        bestLocal = sim
                    }
                }
                // If bestLocal > 0.7, consider it a "fuzzy match"
                if bestLocal > 0.7 { matchedCount += 1 }
            }
            let fuzzyScore = Double(matchedCount) / Double(textTokens.count)
            
            // Combine Jaccard & fuzzy
            let finalScore = (jaccardScore + fuzzyScore) / 2.0
            
            print("Comparing to: \(processedProduct) | Combined similarity: \(finalScore)")
            
            if finalScore > highestScore {
                highestScore = finalScore
                bestMatch = product
            }
        }
        
        // Return best match only if above threshold
        if highestScore >= similarityThreshold {
            return bestMatch
        } else {
            return nil
        }
    }
    
    // MARK: - Levenshtein
    func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let (t, u) = (Array(s1), Array(s2))
        let empty = [Int](repeating: 0, count: u.count + 1)
        var last = [Int](0...u.count)
        
        for i in 1...t.count {
            var cur = [i] + empty[1...]
            for j in 1...u.count {
                cur[j] = (t[i - 1] == u[j - 1])
                    ? last[j - 1]
                    : Swift.min(last[j], cur[j - 1], last[j - 1]) + 1
            }
            last = cur
        }
        
        return last.last!
    }
    
    func tokenSimilarity(_ s1: String, _ s2: String) -> Double {
        let dist = Double(levenshteinDistance(s1, s2))
        let maxLen = Double(max(s1.count, s2.count))
        return 1.0 - (dist / maxLen) // 1 = identical, 0 = totally different
    }
}
