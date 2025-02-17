import SwiftUI

struct CameraContainerView: View {
    @Environment(\.presentationMode) var presentationMode

    // Overlay control
    @State private var showOverlay = false

    // We'll store the raw GPT text separately from the product name
    @State private var overlayGPTText: String = ""
    @State private var overlayProductName: String = ""

    // To reset scanning after dismiss
    @State private var resetScanRequested = false

    var body: some View {
        ZStack {
            // 1) Camera
            CameraTextDetectionView(
                onAnalysisCompleted: { productName, rawGPTText in
                    // Save to local state
                    self.overlayProductName = productName
                    self.overlayGPTText = rawGPTText
                    // Show overlay
                    self.showOverlay = true
                },
                resetRequested: $resetScanRequested
            )
            .edgesIgnoringSafeArea(.all)

            // 2) Floating instructions
            VStack {
                Text("Scan a product label within the box.")
                    .foregroundColor(.white)
                    .padding()
                Spacer()
            }
        }
        // 3) Full‐screen overlay
        .overlay(
            Group {
                if showOverlay {
                    // Parse rating & bullets from the GPT text
                    let parsed = parseOpenAIResponse(overlayGPTText)
                    
                    AnalysisView (
                        productName: overlayProductName,
                        rating: parsed.rating,
                        bulletLines: parsed.bulletLines
                    ) {
                        // Called when user taps "Dismiss"
                        showOverlay = false
                        resetScanRequested = true
                        
                        // Clear the request after setting
                        DispatchQueue.main.async {
                            resetScanRequested = false
                        }
                    }
                }
            }
        )
        .navigationTitle("Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(Theme.accentGreen)
            Text("Back")
                .foregroundColor(Theme.accentGreen)
        })
    }
}

// MARK: - Parsing
extension CameraContainerView {
    /// Given the raw GPT text (e.g. "2\n- Contains dairy...\n- High sugar..."),
    /// extract a numeric rating + bullet lines.
    func parseOpenAIResponse(_ raw: String) -> (rating: Int, bulletLines: [String]) {
        // Split by newline
        var lines = raw
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Attempt to parse the first line as an integer rating
        guard let firstLine = lines.first,
              let rating = Int(firstLine) else {
            // If we can't parse the rating, default to 0
            return (0, lines)
        }
        
        // If parsed rating is valid, remove that line from bullet lines
        lines.removeFirst()
        let bulletLines = lines
        
        return (rating, bulletLines)
    }
}

struct CameraContainerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CameraContainerView()
                .environmentObject(PreferencesModel())
        }
    }
}
