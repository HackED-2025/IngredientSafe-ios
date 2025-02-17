import SwiftUI

struct Theme {
    static let backgroundColor = Color(red: 0.95, green: 0.98, blue: 1.0) // Light pastel
    static let accentGreen = Color(red: 0.27, green: 0.65, blue: 0.44)   // Green accent
    static let textInputBgColor = Color(red: 242/255, green: 242/255, blue: 247/255)

    static let textColor = Color.black
    static let buttonTextColor = Color.white
    static let shadowColor = Color.gray.opacity(0.3)
    static let font: Font = .headline
    static let buttonShape = RoundedRectangle(cornerRadius: 10)
}
