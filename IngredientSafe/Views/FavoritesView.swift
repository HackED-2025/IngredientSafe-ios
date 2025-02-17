import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favoritesModel: FavoritesModel

    var body: some View {
        VStack {
            Text("Your Favorite Products")
                .font(.title)
                .padding()

            List(favoritesModel.favoriteItems, id: \.self) { product in
                HStack {
                    Text(product.name)
                    Spacer()
                    Button(action: {
                        favoritesModel.removeFavorite(product)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Favorites")
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
            .environmentObject(FavoritesModel())
    }
}
