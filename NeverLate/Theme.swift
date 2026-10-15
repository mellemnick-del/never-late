import SwiftUI

/// "Pepsi" GMT palette: burgundy and navy bezel, gilt print, black dial, aged cream lume.
enum Theme {
    static let bg = Color(hex: 0x0A0A0C)
    static let dial = Color(hex: 0x070708)
    static let dialHighlight = Color(hex: 0x1E1E22)
    static let burgundy = Color(hex: 0x801826)
    static let navy = Color(hex: 0x162852)
    static let gilt = Color(hex: 0xD6BA80)
    static let lume = Color(hex: 0xEEE2C4)
    static let lumeHot = Color(hex: 0xFFF8E2)
    static let steel = Color(hex: 0x9A9EA4)      // muted text
    static let metal = Color(hex: 0xC4C8CC)      // case and hands
    static let metalDark = Color(hex: 0x6E7278)
    static let red = Color(hex: 0xE0483F)        // a miss
    static let paper = Color(hex: 0xF2F0EA)
    static let ink = Color(hex: 0x0B0B0C)

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
