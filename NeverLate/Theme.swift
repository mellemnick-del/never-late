import SwiftUI

/// Night dial palette: forest green bezel, lume green-white, steel grey text, red for a miss.
enum Theme {
    static let bg = Color(hex: 0x060A08)
    static let dial = Color(hex: 0x0D1712)
    static let dialHighlight = Color(hex: 0x13241B)
    static let bezel = Color(hex: 0x133524)
    static let green = Color(hex: 0x2C7A54)
    static let lume = Color(hex: 0xC9F2B5)
    static let steel = Color(hex: 0x8EA89A)
    static let red = Color(hex: 0xE0483F)
    static let paper = Color(hex: 0xE9EFE9)
    static let ink = Color(hex: 0x0B120E)

    static func display(_ size: CGFloat) -> Font { .custom("ChakraPetch-Bold", size: size) }
    static func displayMedium(_ size: CGFloat) -> Font { .custom("ChakraPetch-Medium", size: size) }
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
