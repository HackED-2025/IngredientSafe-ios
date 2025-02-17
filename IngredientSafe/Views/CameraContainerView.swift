import SwiftUI

struct CameraContainerView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            CameraTextDetectionView()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Text("Scan a product label within the box.")
                    .foregroundColor(.white)
                    .padding()
                Spacer()
            }
        }
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
