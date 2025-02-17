import Foundation

struct Product: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var description: String
}


class FavoritesModel: ObservableObject {
    @Published var favoriteItems: [Product] {
        didSet {
            // Save to UserDefaults
            if let encodedData = try? JSONEncoder().encode(favoriteItems) {
                UserDefaults.standard.set(encodedData, forKey: "favoriteItems")
            }
        }
    }

    init() {
        // Load from UserDefaults if available
        if let savedData = UserDefaults.standard.data(forKey: "favoriteItems"),
           let decodedItems = try? JSONDecoder().decode([Product].self, from: savedData) {
            self.favoriteItems = decodedItems
        } else {
            self.favoriteItems = []
        }
    }

    func addFavorite(_ product: Product) {
        if !favoriteItems.contains(where: { $0.id == product.id }) {
            favoriteItems.append(product)
        }
    }

    func removeFavorite(_ product: Product) {
        favoriteItems.removeAll { $0.id == product.id }
    }
}
