import Foundation

struct User {
    let id: UUID
    var email: String
    var password: String 
}

struct DietPreference: Identifiable {
    let id = UUID()
    let title: String
    var isSelected: Bool
}

class PreferencesModel: ObservableObject {
    @Published var preferences: [DietPreference] = [
        DietPreference(title: "Diabetes", isSelected: false),
        DietPreference(title: "Celiacs", isSelected: false),
        DietPreference(title: "Halal", isSelected: false),
        DietPreference(title: "Peanuts Allergy", isSelected: false)
    ]

    /// Add a brand new preference, defaulting to not selected
    func addCustomRestriction(_ restriction: String) {
        let newPref = DietPreference(title: restriction, isSelected: false)
        preferences.append(newPref)
    }
    
    /// Toggle logic if needed
    func togglePreference(_ pref: DietPreference) {
        if let index = preferences.firstIndex(where: { $0.id == pref.id }) {
            preferences[index].isSelected.toggle()
        }
    }
}
