import SwiftUI
import CryptoKit
import UniformTypeIdentifiers

// MARK: - Tone Tag

enum ToneTag: String, Codable {
    case calm, balanced, sharp
}

// MARK: - Template Style

enum TemplateStyle: String, Codable {
    case min, journal, story
}

// MARK: - Font Family

enum FontFamily: String, Codable {
    case system
}

// MARK: - Output Size

enum OutputSize: String, Codable, CaseIterable {
    case square    = "1080x1080"
    case landscape = "1200x628"
    case story     = "1080x1920"

    /// SwiftUI proposedSize at @1x; renderer uses scale=3 → output pixel dims
    var proposedSize: CGSize {
        switch self {
        case .square:    return CGSize(width: 360, height: 360)
        case .landscape: return CGSize(width: 400, height: 209.33)
        case .story:     return CGSize(width: 360, height: 640)
        }
    }

    /// Minimum primary font size in SwiftUI points (spec: min px 42/32/48 ÷ 3x scale)
    var minFontSize: CGFloat {
        switch self {
        case .square:    return 14   // 42px / 3
        case .landscape: return 11   // 32px / 3
        case .story:     return 16   // 48px / 3
        }
    }

    var renderScale: CGFloat { 3.0 }
}

// MARK: - Errors

enum ShareCardError: Error, LocalizedError {
    case badInput(field: String, message: String)   // E_BAD_INPUT
    case colorContrast(message: String)              // E_COLOR_CONTRAST
    case layoutOverflow(message: String)             // E_LAYOUT_OVERFLOW
    case renderFail(message: String)                 // E_RENDER_FAIL

    var errorDescription: String? {
        switch self {
        case .badInput(_, let m):   return m
        case .colorContrast(let m): return m
        case .layoutOverflow(let m): return m
        case .renderFail(let m):    return m
        }
    }
}

// MARK: - Input

struct ShareCardInput {
    var userDisplayName: String?
    var date: Date
    var insightText: String
    var toneTag: ToneTag         = .calm
    var intensity: Int           = 2        // 1–3
    var templateStyle: TemplateStyle = .min
    var backgroundColor: Color?             // nil → AppTheme.earth
    var accentColor: Color?                 // nil → AppTheme.textPrimary
    var fontFamily: FontFamily   = .system
    var includeBranding: Bool    = true
    var brandLogoURL: URL?                  // nil → text watermark fallback
    var locale: Locale           = .current
    var outputSize: OutputSize   = .square
    // Extra Saju context (populated from DailyInsight)
    var dayElement: String?
    var elementTheme: String?
    var dynamicText: String?

    static func from(_ insight: DailyInsight, userName: String? = nil) -> ShareCardInput {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: insight.localDate) ?? Date()
        return ShareCardInput(
            userDisplayName: userName,
            date: date,
            insightText: insight.insightText,
            toneTag: toneTag(for: insight.dayElement),
            dayElement: insight.dayElement,
            elementTheme: insight.elementTheme,
            dynamicText: insight.dynamicText
        )
    }

    private static func toneTag(for element: String?) -> ToneTag {
        switch element?.lowercased() {
        case "metal": return .sharp
        case "water": return .balanced
        default:      return .calm
        }
    }
}

// MARK: - Shareable image wrapper (UIImage → Transferable)

struct ShareableCard: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { card in
            card.image.pngData() ?? Data()
        }
    }
}

// MARK: - Manifest

struct ShareCardManifest: Codable {
    struct Metadata: Codable {
        let date: Date
        let toneTag: String
        let intensity: Int
        let templateStyle: String
        let backgroundColor: String   // hex
        let accentColor: String       // hex
        let outputSize: String
        // text_bounds flattened (CGRect is not Codable)
        let textBoundsX: CGFloat
        let textBoundsY: CGFloat
        let textBoundsWidth: CGFloat
        let textBoundsHeight: CGFloat
    }

    let imageURL: URL?            // nil for local share
    let metadata: Metadata
    let accessibilityText: String
    let renderSeed: String        // hex SHA-256 of stable inputs
    let templateHash: String      // hex SHA-256 of template version string
}
