import SwiftUI

struct MainView: View {
    @EnvironmentObject var authVM: AuthViewModel

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
                    
                    Text("Hello, \(authVM.currentUser?.email ?? "User")!")
                        .font(.title)
                        .foregroundColor(.gray)
                }
                .padding(.top, 50)
                
                // 3) Action Buttons
                VStack(spacing: 16) {
                    NavigationLink(value: Destination.camera) {
                        Text("Begin Scanning")
                            .foregroundColor(.white)
                            .font(Theme.font)
                            .frame(width: 320, height: 60)
                            .background(Theme.accentGreen)
                            .clipShape(Theme.buttonShape)
                            .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    NavigationLink(value: Destination.preferences) {
                        Text("Customize Dietary Restrictions")
                            .foregroundColor(.white)
                            .font(Theme.font)
                            .frame(width: 320, height: 60)
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
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MainView()
                .environmentObject(AuthViewModel())
        }
    }
}
