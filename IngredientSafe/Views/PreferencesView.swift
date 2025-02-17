import SwiftUI

extension UIApplication {
    /// Simple helper to dismiss the keyboard from anywhere
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder),
                   to: nil, from: nil, for: nil)
    }
}

struct PreferencesView: View {
    @EnvironmentObject var preferencesModel: PreferencesModel
    @Environment(\.presentationMode) var presentationMode

    // For new restrictions
    @State private var customRestrictionInput: String = ""

    // For searching existing preferences
    @State private var searchText: String = ""

    var body: some View {
        ZStack {
            Theme.backgroundColor
                .ignoresSafeArea()

            VStack(alignment: .leading) {

                // Header
                VStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(Theme.accentGreen)

                    Text("Preferences/Restrictions")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(Theme.accentGreen)
                }

                // Search Bar
                TextField(
                    "Search preferences...",
                    text: $searchText,
                    prompt: Text("Search preferences...").foregroundStyle(Color(.gray))
                )
                    .padding()
                    .frame(height: 40) // match button or anything you like
                    .background(Theme.textInputBgColor)
                    .cornerRadius(10)
                    .foregroundColor(Theme.textColor)
                    .padding(.horizontal)

                // Main list of preferences (both default + user added), filtered
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredPreferences) { pref in
                            // Need a binding for the toggle. We'll find it by id:
                            if let index = preferencesModel.preferences.firstIndex(where: { $0.id == pref.id }) {
                                Toggle(
                                    preferencesModel.preferences[index].title,
                                    isOn: $preferencesModel.preferences[index].isSelected
                                )
                                .toggleStyle(SwitchToggleStyle(tint: Theme.accentGreen))
                                .padding()
                                .background(Color(UIColor.systemGreen).opacity(0.15))
                                .foregroundStyle(.gray)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Divider().padding(.vertical, 8)

                Text("Add a Custom Restriction:")
                    .font(.headline)
                    .foregroundColor(Theme.textColor)
                    .padding(.horizontal)

                // TextField + Add Button side by side
                HStack {
                    TextField(
                        "Add new restriction...",
                        text: $customRestrictionInput,
                        prompt: Text("Add new restriction...")
                            .foregroundStyle(Color(.gray))
                    )
                    .padding(.horizontal)
                    .frame(height: 40)  // match the button's height
                    .background(Theme.textInputBgColor)
                    .foregroundColor(Theme.textColor)
                    .cornerRadius(10)

                    Button(action: addCustomRestriction) {
                        Text("Add")
                            .foregroundColor(.white)
                            .font(Theme.font)
                            .frame(width: 80, height: 40)
                            .background(Theme.accentGreen)
                            .clipShape(Theme.buttonShape)
                            .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(Theme.accentGreen)
            Text("Back")
                .foregroundColor(Theme.accentGreen)
        })
    }

    /// Filtered preferences based on user’s search
    private var filteredPreferences: [DietPreference] {
        let lowerSearch = searchText.lowercased()
        if lowerSearch.isEmpty {
            return preferencesModel.preferences
        } else {
            return preferencesModel.preferences.filter { pref in
                pref.title.lowercased().contains(lowerSearch)
            }
        }
    }

    private func addCustomRestriction() {
        guard !customRestrictionInput.isEmpty else { return }
        preferencesModel.addCustomRestriction(customRestrictionInput)
        customRestrictionInput = ""

        // Dismiss keyboard
        UIApplication.shared.endEditing()
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PreferencesView()
                .environmentObject(PreferencesModel())
        }
    }
}
