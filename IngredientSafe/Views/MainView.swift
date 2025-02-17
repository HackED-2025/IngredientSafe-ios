import SwiftUI

struct MainView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Hello, \(authVM.currentUser?.email ?? "User")!")
                .font(.largeTitle)
            
            NavigationLink("Begin Scanning", value: Destination.camera)
                .padding()
            
            NavigationLink("Customize Dietary Restrictions", value: Destination.preferences)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Main Page")
        .padding()
    }
}
