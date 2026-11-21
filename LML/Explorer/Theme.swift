import SwiftUI

/// The website's palette (`src/index.css` in lml_frontend_client).
extension Color {
    static let night = Color(red: 0x0B / 255, green: 0x0B / 255, blue: 0x0F / 255)
    static let nightRaised = Color(red: 0x14 / 255, green: 0x14 / 255, blue: 0x1C / 255)
    static let nightChip = Color(red: 0x1B / 255, green: 0x1B / 255, blue: 0x24 / 255)
    static let nightLine = Color(red: 0x1E / 255, green: 0x1E / 255, blue: 0x26 / 255)
    static let ink = Color(red: 0xF4 / 255, green: 0xF2 / 255, blue: 0xF0 / 255)
    static let inkMuted = Color(red: 0x8C / 255, green: 0x8C / 255, blue: 0x9A / 255)
    static let inkChip = Color(red: 0xC9 / 255, green: 0xC7 / 255, blue: 0xD2 / 255)
    static let inkDim = Color(red: 0x4A / 255, green: 0x4A / 255, blue: 0x5A / 255)
    static let lmlPink = Color(red: 0xD9 / 255, green: 0x3A / 255, blue: 0x87 / 255)
    static let lmlPinkLight = Color(red: 0xFF / 255, green: 0x7E / 255, blue: 0xB6 / 255)
    /// Tailwind's amber-200 and amber-950, for the series badge.
    static let seriesBackground = Color(red: 0xFE / 255, green: 0xE6 / 255, blue: 0x85 / 255)
    static let seriesInk = Color(red: 0x46 / 255, green: 0x19 / 255, blue: 0x01 / 255)
}
