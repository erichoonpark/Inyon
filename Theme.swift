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
}
