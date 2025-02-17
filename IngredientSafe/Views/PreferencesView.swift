import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var preferencesModel: PreferencesModel
    @State private var customRestrictionInput: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Dietary Conditions")
                .font(.title2)
                .padding(.bottom, 5)
            
            // Show each known preference with a toggle
            List {
                ForEach($preferencesModel.preferences) { $pref in
                    Toggle(pref.title, isOn: $pref.isSelected)
                }
            }
            
            Divider().padding(.vertical, 8)
            
            Text("Custom Restrictions:")
                .font(.headline)
            // Show existing custom restrictions
            ForEach(preferencesModel.customRestrictions, id: \.self) { restriction in
                Text("• \(restriction)")
            }
            
            HStack {
                TextField("Add new restriction...", text: $customRestrictionInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Add") {
                    if !customRestrictionInput.isEmpty {
                        preferencesModel.addCustomRestriction(customRestrictionInput)
                        customRestrictionInput = ""
                    }
                }
            }
            
            Spacer()
        }
        .navigationTitle("Preferences")
        .padding()
    }
}
