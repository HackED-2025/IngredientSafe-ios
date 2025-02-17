import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favoritesModel: FavoritesModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Theme.backgroundColor
                .ignoresSafeArea()

            VStack(alignment: .leading) {

                // Header
                VStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(Theme.accentGreen)

                    Text("Favorites")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(Theme.accentGreen)
                }

                // Main List of Favorite Products
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(favoritesModel.favoriteItems, id: \.self) { product in
                            HStack {
                                Text(product.name)
                                    .foregroundColor(Theme.textColor)
                                    .padding()
                                Spacer()
                                Button(action: {
                                    favoritesModel.removeFavorite(product)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .padding()
                                        .background(Theme.textInputBgColor)
                                        .clipShape(Circle())
                                }
                            }
                            .padding()
                            .background(Theme.textInputBgColor)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }

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
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FavoritesView()
                .environmentObject(FavoritesModel())
        }
    }
}
