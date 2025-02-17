import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    
    // For real apps, you’d do real sign-up logic here
    func signUp(email: String, password: String) {
        let newUser = User(id: UUID(), email: email, password: password)
        // In a real app, you'd call a backend. For now, just set it as logged in.
        currentUser = newUser
    }
    
    func login(email: String, password: String) -> Bool {
        // For demonstration, we accept any password if it’s the same email used at sign-up
        // In a real app, do real checks
        if let user = currentUser, user.email == email, user.password == password {
            print("Login success")
            return true
        }
        print("Login failed – either no user or mismatch")
        return false
    }
}
