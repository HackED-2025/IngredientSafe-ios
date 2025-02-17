import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPass = ""
    @State private var showMismatch = false
    
    var body: some View {
        VStack {
            Text("Create an Account")
                .font(.headline)
            
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            SecureField("Confirm Password", text: $confirmPass)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            if showMismatch {
                Text("Passwords do not match!")
                    .foregroundColor(.red)
            }
            
            Button("Sign Up") {
                if password == confirmPass {
                    authVM.signUp(email: email, password: password)
                    dismiss()
                } else {
                    showMismatch = true
                }
            }
            .padding()
        }
        .padding()
        .navigationTitle("Sign Up")
    }
}
