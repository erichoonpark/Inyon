import SwiftUI
import CryptoKit

// MARK: - Share Card Renderer

@MainActor
final class ShareCardRenderer {

    // MARK: - Public API

    func render(input: ShareCardInput) throws -> (UIImage, ShareCardManifest) {
        try validate(input)
        let (bg, accent) = try resolveColors(input)
        let seed = computeRenderSeed(input)
        let hash = computeTemplateHash(input.templateStyle)
        let size = input.outputSize

        let view = cardView(input: input, bg: bg, accent: accent, seed: seed)
            .frame(width: size.proposedSize.width, height: size.proposedSize.height)

        let renderer = ImageRenderer(content: view)
        renderer.scale = size.renderScale
        guard let image = renderer.uiImage else {
            throw ShareCardError.renderFail(message: "ImageRenderer returned nil")
        }

        let manifest = buildManifest(input: input, bg: bg, accent: accent, seed: seed, hash: hash)
        return (image, manifest)
    }

    // MARK: - Validation

    private func validate(_ input: ShareCardInput) throws {
        guard !input.insightText.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ShareCardError.badInput(field: "insight_text", message: "insight_text is required")
        }
        guard (1...3).contains(input.intensity) else {
            throw ShareCardError.badInput(field: "intensity", message: "intensity must be 1–3")
        }
        // Pre-check: insight text that's very long won't fit in 3 lines at minimum font size
        if input.insightText.count > 220 {
            throw ShareCardError.layoutOverflow(
                message: "insight_text too long for 3-line layout at minimum font size")
        }
    }

    // MARK: - Color resolution
    // Spec: prefer accent_color, else white, else black, else E_COLOR_CONTRAST

    private func resolveColors(_ input: ShareCardInput) throws -> (bg: Color, accent: Color) {
        let bg = input.backgroundColor ?? AppTheme.earth
        let preferred = input.accentColor ?? AppTheme.textPrimary
        if contrastRatio(bg, preferred) >= 4.5 { return (bg, preferred) }
        if contrastRatio(bg, .white) >= 4.5 { return (bg, .white) }
        if contrastRatio(bg, .black) >= 4.5 { return (bg, .black) }
        throw ShareCardError.colorContrast(
            message: "Background has insufficient contrast (< 4.5:1) with any text color")
    }

    // MARK: - WCAG relative luminance & contrast ratio

    private func contrastRatio(_ a: Color, _ b: Color) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    private func luminance(_ color: Color) -> Double {
        guard let components = UIColor(color).cgColor.components, components.count >= 3 else {
            return 0
        }
        func linear(_ v: CGFloat) -> Double {
            let d = Double(v)
            return d <= 0.04045 ? d / 12.92 : pow((d + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(components[0])
             + 0.7152 * linear(components[1])
             + 0.0722 * linear(components[2])
    }

    // MARK: - Deterministic seed & template hash

    private func computeRenderSeed(_ input: ShareCardInput) -> String {
        let iso = ISO8601DateFormatter()
        let stable = [
            input.insightText,
            input.toneTag.rawValue,
            "\(input.intensity)",
            input.templateStyle.rawValue,
            input.outputSize.rawValue,
            input.locale.identifier,
            iso.string(from: input.date)
        ].joined(separator: "|")
        return SHA256.hash(data: Data(stable.utf8))
            .compactMap { String(format: "%02x", $0) }.joined()
    }

    private func computeTemplateHash(_ style: TemplateStyle) -> String {
        let version = "inyon_share_card_\(style.rawValue)_v1"
        return SHA256.hash(data: Data(version.utf8))
            .compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - View dispatch

    @ViewBuilder
    private func cardView(input: ShareCardInput, bg: Color, accent: Color, seed: String) -> some View {
        let direction: LayoutDirection = {
            let lang = input.locale.language.languageCode?.identifier ?? ""
            return (lang == "ar" || lang == "he") ? .rightToLeft : .leftToRight
        }()

        Group {
            switch input.templateStyle {
            case .min:
                MinShareCardView(input: input, bg: bg, accent: accent, seed: seed)
            case .journal:
                JournalShareCardView(input: input, bg: bg, accent: accent, seed: seed)
            case .story:
                StoryShareCardView(input: input, bg: bg, accent: accent, seed: seed)
            }
        }
        .environment(\.layoutDirection, direction)
    }

    // MARK: - Manifest

    private func buildManifest(
        input: ShareCardInput,
        bg: Color,
        accent: Color,
        seed: String,
        hash: String
    ) -> ShareCardManifest {
        let size = input.outputSize
        let margin = size.proposedSize.width * 0.10
        let textBounds = CGRect(
            x: margin, y: margin,
            width: size.proposedSize.width * 0.80,
            height: size.proposedSize.height * 0.80
        )
        let accessText = [input.insightText, input.dynamicText]
            .compactMap { $0 }.joined(separator: " ")

        return ShareCardManifest(
            imageURL: nil,
            metadata: .init(
                date: input.date,
                toneTag: input.toneTag.rawValue,
                intensity: input.intensity,
                templateStyle: input.templateStyle.rawValue,
                backgroundColor: bg.hexString,
                accentColor: accent.hexString,
                outputSize: input.outputSize.rawValue,
                textBoundsX: textBounds.minX,
                textBoundsY: textBounds.minY,
                textBoundsWidth: textBounds.width,
                textBoundsHeight: textBounds.height
            ),
            accessibilityText: accessText,
            renderSeed: seed,
            templateHash: hash
        )
    }
}

// MARK: - Color hex helper

extension Color {
    var hexString: String {
        let c = UIColor(self)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
