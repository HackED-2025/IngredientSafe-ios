import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var loginFailed = false

    var body: some View {
        ZStack {
            // 1) Background
            Theme.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 30) {
                
                // 2) Brand / Header
                VStack(spacing: 8) {
                    Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(Theme.accentGreen)
                    
                    Text("INGREDIA")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(Theme.accentGreen)
                    
                    Text("Please log in to continue")
                        .foregroundColor(.gray)
                }
                .padding(.top, 50)
                
                // 3) Input Fields
                VStack(spacing: 16) {
                    TextField(
                        "Email",
                        text: $email,
                        prompt: Text("Email").foregroundStyle(Color(.gray))
                    )
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Theme.textInputBgColor)
                        .foregroundStyle(.red)
                        .cornerRadius(10)
                        .keyboardType(.emailAddress)

                    SecureField(
                        "Password",
                        text: $password,
                        prompt: Text("Password").foregroundStyle(Color(.gray))
                    )
                        .padding()
                        .background(Theme.textInputBgColor)
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
                            .font(Theme.font)
                            .frame(width: 200, height: 40)
                            .background(Theme.accentGreen)
                            .clipShape(Theme.buttonShape)
                            .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    NavigationLink(destination: SignUpView()) {
                        Text("Sign Up")
                            .foregroundColor(.white)
                            .font(Theme.font)
                            .frame(width: 200, height: 40)
                            .background(Theme.accentGreen)
                            .clipShape(Theme.buttonShape)
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
