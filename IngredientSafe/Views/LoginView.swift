import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var loginFailed = false

    var body: some View {
        VStack {
            Text("Welcome! Please login or sign up.")
                .font(.headline)
            
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            if loginFailed {
                Text("Login failed. Check credentials or sign up.")
                    .foregroundColor(.red)
            }
            
            HStack {
                Button("Login") {
                    let success = authVM.login(email: email, password: password)
                    if !success {
                        loginFailed = true
                    }
                }
                .padding()
                
                NavigationLink("Sign Up") {
                    SignUpView()
                }
                .padding()
            }
        }
        .padding()
        .navigationTitle("Login")
    }
}
