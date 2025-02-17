import SwiftUI

struct CameraContainerView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Tracks whether we should show the full-screen overlay
    @State private var showOverlay = false
    
    // Holds the text or message returned by OpenAI
    @State private var overlayText: String = ""
    
    // When set to true, we'll tell the VC to reset scanning
    @State private var resetScanRequested = false
    
    var body: some View {
        ZStack {
            // Our camera view
            CameraTextDetectionView(
                // This closure is called when analysis is done
                onAnalysisCompleted: { openAIResponse in
                    // Store the result in local state
                    self.overlayText = openAIResponse
                    // Show the overlay
                    self.showOverlay = true
                },
                // A binding so we can request a reset
                resetRequested: $resetScanRequested
            )
            .edgesIgnoringSafeArea(.all)

            VStack {
                Text("Scan a product label within the box.")
                    .foregroundColor(.white)
                    .padding()
                Spacer()
            }
        }
        // Full‐screen overlay that covers the camera
        .overlay(
            Group {
                if showOverlay {
                    ZStack {
                        // Dark background
                        Color.black.opacity(0.8)
                            .edgesIgnoringSafeArea(.all)
                        
                        // Example of a basic overlay layout
                        VStack(spacing: 16) {
                            Text("Analysis Result")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ScrollView {
                                Text(overlayText)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            
                            Button(action: {
                                // Dismiss the overlay
                                showOverlay = false
                                
                                // Request that the camera resets scanning
                                resetScanRequested = true
                                
                                // Once the representable sees our request, it’ll call
                                // resetScan() in the UIViewController, so scanning restarts.
                                // Then we clear the flag so it won't keep toggling.
                                DispatchQueue.main.async {
                                    resetScanRequested = false
                                }
                            }) {
                                Text("Dismiss")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(width: 120)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
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

struct CameraContainerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CameraContainerView()
                .environmentObject(PreferencesModel())
        }
    }
}
