import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPass = ""
    @State private var showMismatch = false
    
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
                    
                    Text("Create an account to continue")
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
                    
                    SecureField(
                        "Confirm Password",
                        text: $confirmPass,
                        prompt: Text("Confirm Password").foregroundStyle(Color(.gray))
                    )
                    .padding()
                    .background(Theme.textInputBgColor)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // 4) Password Mismatch Warning
                if showMismatch {
                    Text("Passwords do not match!")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // 5) Action Buttons
                VStack(spacing: 16) {
                    Button(action: handleSignUp) {
                        Text("Sign Up")
                            .foregroundColor(.white)
                            .font(Theme.font)
                            .frame(width: 200, height: 40)
                            .background(Theme.accentGreen)
                            .clipShape(Theme.buttonShape)
                            .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .foregroundColor(.white)
                            .font(Theme.font)
                            .frame(width: 200, height: 40)
                            .background(Color.red)
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
    
    private func handleSignUp() {
        if password == confirmPass {
            authVM.signUp(email: email, password: password)
            dismiss()
        } else {
            showMismatch = true
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SignUpView()
                .environmentObject(AuthViewModel())
        }
    }
}
