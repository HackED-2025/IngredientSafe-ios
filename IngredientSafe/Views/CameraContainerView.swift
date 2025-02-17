import SwiftUI

struct CameraContainerView: View {
    var body: some View {
        ZStack {
            CameraTextDetectionView()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Scan a product label within the red box.")
                    .foregroundColor(.white)
                    .padding()
                Spacer()
            }
        }
        .navigationTitle("Scanner")
        .navigationBarTitleDisplayMode(.inline)
    }
}
