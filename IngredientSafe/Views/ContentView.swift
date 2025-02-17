import SwiftUI

struct ContentView: View {
    // We keep an instance of AuthViewModel and PreferencesModel in the environment
    @StateObject var authVM = AuthViewModel()
    @StateObject var preferences = PreferencesModel()
    
    var body: some View {
        NavigationView {
            if authVM.currentUser == nil {
                // Show login flow if no user
                LoginView()
            } else {
                // Show main content if logged in
                MainView()
            }
        }
    }
}
