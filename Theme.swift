import SwiftUI

// MARK: - App Theme

enum AppTheme {

    // MARK: - Colors

    /// Korean green "Earth" background
    static let earth = Color(red: 0.08, green: 0.28, blue: 0.22)

    /// Primary text - warm off-white
    static let textPrimary = Color(red: 0.96, green: 0.95, blue: 0.92)

    /// Secondary text - muted sage
    static let textSecondary = Color(red: 0.78, green: 0.82, blue: 0.78)

    /// Divider/border color
    static let divider = textPrimary.opacity(0.1)

    /// Underline accent
    static let underline = textPrimary

    /// Surface overlay for subtle layering
    static let surface = Color.white.opacity(0.03)

    // MARK: - Korean Red Mountain (Joseon Vermilion)

    /// Nav bar background - mineral, earth-based red
    static let earthRed = Color(
        red: 200/255,
        green: 58/255,
        blue: 50/255
    ) // Hex: #C83A32

    /// Primary text on red - warm off-white
    static let textOnRedPrimary = Color(
        red: 0.98,
        green: 0.96,
        blue: 0.93
    )

    /// Muted text on red
    static let textOnRedMuted = Color.white.opacity(0.55)

    /// Divider on red background
    static let dividerOnRed = Color.white.opacity(0.18)
}
