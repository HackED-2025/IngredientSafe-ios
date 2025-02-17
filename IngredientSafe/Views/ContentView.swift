import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            if authVM.currentUser != nil {
                MainView()
                    .navigationDestination(for: Destination.self) { destination in
                        switch destination {
                        case .camera:
                            CameraContainerView()
                        case .preferences:
                            PreferencesView()
                        case .signUp:
                            SignUpView()
                        }
                    }
            } else {
                LoginView()
                    .navigationDestination(for: Destination.self) { destination in
                        switch destination {
                        case .signUp:
                            SignUpView()
                        default:
                            EmptyView()
                        }
                    }
            }
        }
    }
}

enum Destination: Hashable {
    case camera
    case preferences
    case signUp
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
            .environmentObject(PreferencesModel())
    }
}
