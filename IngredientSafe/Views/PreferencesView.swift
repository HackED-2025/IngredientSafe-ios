import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var preferencesModel: PreferencesModel
    @Environment(\.presentationMode) var presentationMode
    @State private var customRestrictionInput: String = ""

    var body: some View {
        ZStack {
            Theme.backgroundColor
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(Theme.accentGreen)

                    Text("Preferences")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(Theme.accentGreen)
                }
                .padding(.top, 30)

                Text("Dietary Conditions")
                    .font(.title2)
                    .foregroundColor(Theme.textColor)

                ScrollView {
                      VStack(spacing: 12) {
                          ForEach($preferencesModel.preferences) { $pref in
                              Toggle(pref.title, isOn: $pref.isSelected)
                                  .toggleStyle(SwitchToggleStyle(tint: Theme.accentGreen))
                                  .padding()
                                  .background(Color(UIColor.systemGreen).opacity(0.15))
                                  .foregroundStyle(.gray)
                                  .cornerRadius(10)
                          }
                      }
                  }

                Divider().padding(.vertical, 8)

                Text("Custom Restrictions:")
                    .font(.headline)
                    .foregroundColor(Theme.textColor)

                ForEach(preferencesModel.customRestrictions, id: \.self) { restriction in
                    Text("• \(restriction)")
                        .foregroundColor(Theme.textColor)
                }

                HStack {
                    TextField(
                        "Add new restriction...",
                        text: $customRestrictionInput,
                        prompt: Text("Add new restriction...").foregroundStyle(Color(.gray))
                    )
                        .padding()
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
        .navigationBarTitle("Preferences", displayMode: .inline)
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

    private func addCustomRestriction() {
        if !customRestrictionInput.isEmpty {
            preferencesModel.addCustomRestriction(customRestrictionInput)
            customRestrictionInput = ""
        }
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
