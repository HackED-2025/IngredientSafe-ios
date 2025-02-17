import SwiftUI

/// A full‐screen overlay that shows rating, product name & bullet lines
struct AnalysisView: View {
    let productName: String
    let rating: Int
    let bulletLines: [String]
    let onDismiss: () -> Void
    
    @EnvironmentObject var favoritesModel: FavoritesModel

    var body: some View {
        ZStack {
            Theme.backgroundColor
                .edgesIgnoringSafeArea(.all)

            // The "card" with rating & bullet lines
            VStack(spacing: 20) {
                
                // 1) Product name
                Text(productName)
                    .font(.title)
                    .foregroundColor(Theme.accentGreen)
                    .padding(.top, 16)
                
                // 2) Rating bubble
                ratingBubble
                
                // 3) Bullets
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(bulletLines, id: \.self) { bullet in
                            bulletRow(bullet)
                        }
                    }
                    .padding(.horizontal)
                }

                // 4) Add to Favorites Button
                Button(action: addToFavorites) {
                    Text("Add to Favorites")
                        .foregroundColor(.white)
                        .font(Theme.font)
                        .padding()
                        .frame(width: 200, height: 40)
                        .background(Theme.accentGreen)
                        .cornerRadius(8)
                        .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 16)

                // 5) Dismiss button
                Button(action: onDismiss) {
                    Text("Dismiss")
                        .foregroundColor(.white)
                        .font(Theme.font)
                        .padding()
                        .frame(width: 120)
                        .background(Theme.accentGreen)
                        .cornerRadius(8)
                }
                .padding(.bottom, 16)
            }
            .padding()
            .background(Theme.backgroundColor)
            .cornerRadius(20)
            .padding(.horizontal, 32)
            .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 4)
        }
    }

    /// The colored rating at the top.
    private var ratingBubble: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(ratingColor)
                .frame(width: 80, height: 80)

            Text("\(rating)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
        }
    }

    /// A color scale for rating. Adjust thresholds as desired.
    private var ratingColor: Color {
        switch rating {
        case ..<1:
            return .gray  // handle 0 or invalid
        case 1...3:
            return .red
        case 4...6:
            return .orange
        default:
            return Theme.accentGreen
        }
    }

    /// A single bullet line: "• text..."
    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top) {
            Text("•")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.accentGreen)
                .padding(.trailing, 6)

            Text(text)
                .foregroundColor(.gray)
        }
    }

    /// Function to add product to favorites
    private func addToFavorites() {
        let product = Product(id: UUID().uuidString, name: productName, description: bulletLines.joined(separator: ", "))
        favoritesModel.addFavorite(product)
        print("\(productName) added to favorites")
    }
}
