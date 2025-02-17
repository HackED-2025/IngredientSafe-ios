import SwiftUI

struct MainView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Hello, \(authVM.currentUser?.email ?? "User")!")
                .font(.largeTitle)
            
            NavigationLink("Begin Scanning") {
                CameraContainerView()
            }
            .padding()
            
            NavigationLink("Customize Dietary Restrictions") {
                PreferencesView()
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Main Page")
        .padding()
    }
}
