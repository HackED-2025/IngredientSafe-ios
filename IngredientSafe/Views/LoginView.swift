import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var loginFailed = false

    // Example brand colors; tweak these as needed.
    private let backgroundColor = Color(red: 0.95, green: 0.98, blue: 1.0) // Light pastel
    private let accentGreen = Color(red: 0.27, green: 0.65, blue: 0.44)   // Approx. #44A36F

    var body: some View {
        ZStack {
            // 1) Background
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 30) {
                
                // 2) Brand / Header
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(accentGreen)
                    
                    Text("INGREDIA")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(accentGreen)
                    
                    Text("Please log in to continue")
                        .foregroundColor(.gray)
                }
                .padding(.top, 50)
                
                // 3) Input Fields
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // 4) Login status
                if loginFailed {
                    Text("Login failed. Check credentials or sign up.")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // 5) Action Buttons
                VStack(spacing: 16) {
                    Button(action: handleLogin) {
                        Text("Login")
                            .foregroundColor(.white)
                            .font(.headline)
                            .frame(width: 200, height: 40)
                            .background(accentGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    NavigationLink(destination: SignUpView()) {
                        Text("Sign Up")
                            .foregroundColor(.white)
                            .font(.headline)
                            .frame(width: 200, height: 40)
                            .background(accentGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }

                Spacer()
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
    }

    private func handleLogin() {
        let success = authVM.login(email: email, password: password)
        if success {
            // Navigate to MainView
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = UIHostingController(
                    rootView: MainView()
                        .environmentObject(authVM)
                )
                window.makeKeyAndVisible()
            }
        } else {
            loginFailed = true
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LoginView()
                .environmentObject(AuthViewModel())
        }
    }
}
