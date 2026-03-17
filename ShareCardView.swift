import SwiftUI
import CryptoKit

// MARK: - Seeded RNG

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: String) {
        let hash = SHA256.hash(data: Data(seed.utf8))
        self.state = hash.withUnsafeBytes { $0.load(as: UInt64.self) }
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    mutating func nextDouble() -> Double {
        Double(next()) / Double(UInt64.max)
    }
}

// MARK: - Grain Overlay

struct GrainOverlay: View {
    let seed: String
    var opacity: Double = 0.018

    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRNG(seed: seed)
            let count = Int(size.width * size.height / 500)
            for _ in 0..<count {
                let x = rng.nextDouble() * Double(size.width)
                let y = rng.nextDouble() * Double(size.height)
                let r = rng.nextDouble() * 1.0 + 0.5
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                    with: .color(.white)
                )
            }
        }
        .opacity(opacity)
        .allowsHitTesting(false)
    }
}

// MARK: - Branding logo helper

private struct BrandLogo: View {
    let url: URL?
    let accentColor: Color

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit().frame(height: 20)
                default:
                    wordmark
                }
            }
        } else {
            wordmark
        }
    }

    private var wordmark: some View {
        Text("INYON")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .tracking(1.5)
            .foregroundColor(accentColor)
    }
}

// MARK: - Formatted date helper

private func formattedDate(_ date: Date, locale: Locale) -> String {
    let f = DateFormatter()
    f.locale = locale
    f.dateStyle = .medium
    f.timeStyle = .none
    return f.string(from: date)
}

// MARK: - Template: min (minimal)

struct MinShareCardView: View {
    let input: ShareCardInput
    let bg: Color
    let accent: Color
    let seed: String

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            GrainOverlay(seed: seed)

            VStack(alignment: .leading, spacing: 0) {
                // Header: logo + date
                HStack {
                    BrandLogo(url: input.includeBranding ? input.brandLogoURL : nil,
                              accentColor: accent)
                    Spacer()
                    Text(formattedDate(input.date, locale: input.locale))
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(accent.opacity(0.6))
                }

                Spacer()

                // Main insight text
                Text(input.insightText)
                    .font(.system(size: 19, weight: .regular))
                    .foregroundColor(accent)
                    .lineSpacing(6)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: false)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Element context
                if let element = input.dayElement, let theme = input.elementTheme {
                    Text("\(element)  ·  \(theme)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(accent.opacity(0.5))
                        .lineLimit(1)
                        .padding(.bottom, 12)
                }

                // Watermark
                if input.includeBranding {
                    Text("INYON")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(accent.opacity(0.25))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(32)
        }
    }
}

// MARK: - Template: journal

struct JournalShareCardView: View {
    let input: ShareCardInput
    let bg: Color
    let accent: Color
    let seed: String

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            GrainOverlay(seed: seed)

            VStack(alignment: .leading, spacing: 0) {
                // Header row
                HStack {
                    Text("INYON")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .tracking(1.5)
                        .foregroundColor(accent)
                    Spacer()
                    Text(formattedDate(input.date, locale: input.locale))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(accent.opacity(0.55))
                }
                .padding(.bottom, 12)

                // Divider
                Rectangle()
                    .fill(accent.opacity(0.2))
                    .frame(height: 1)
                    .padding(.bottom, 16)

                // Element context
                if let element = input.dayElement, let theme = input.elementTheme {
                    Text("\(element)  ·  \(theme)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(accent.opacity(0.55))
                        .padding(.bottom, 16)
                }

                // Main insight text with quote marks
                VStack(alignment: .leading, spacing: 4) {
                    Text("\u{201C}\(input.insightText)\u{201D}")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(accent)
                        .lineSpacing(5)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: false)
                }

                // Dynamic text
                if let dynamic = input.dynamicText {
                    Spacer().frame(height: 14)
                    Text("\u{201C}\(dynamic)\u{201D}")
                        .font(.system(size: 13, weight: .regular))
                        .italic()
                        .foregroundColor(accent.opacity(0.7))
                        .lineSpacing(4)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: false)
                }

                Spacer()

                // Footer divider + URL
                Rectangle()
                    .fill(accent.opacity(0.2))
                    .frame(height: 1)
                    .padding(.bottom, 12)

                Text("inyon.app")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(accent.opacity(0.4))
            }
            .padding(32)
        }
    }
}

// MARK: - Template: story (9:16)

struct StoryShareCardView: View {
    let input: ShareCardInput
    let bg: Color
    let accent: Color
    let seed: String

    private func elementIcon(for element: String?) -> String {
        switch element?.lowercased() {
        case "wood":  return "leaf"
        case "fire":  return "flame"
        case "earth": return "mountain.2"
        case "metal": return "circle.hexagongrid"
        case "water": return "drop"
        default:      return "circle"
        }
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            GrainOverlay(seed: seed)

            VStack(spacing: 0) {
                // Top zone (~25%): brand + date + optional user name
                VStack(spacing: 8) {
                    if input.includeBranding {
                        Text("INYON")
                            .font(.system(size: 22, weight: .semibold, design: .monospaced))
                            .tracking(3)
                            .foregroundColor(accent)
                    }
                    Text(formattedDate(input.date, locale: input.locale))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(accent.opacity(0.55))
                    if let name = input.userDisplayName {
                        Text(name)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(accent.opacity(0.4))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 48)

                Spacer()

                // Middle zone (~50%): element icon + insight
                VStack(alignment: .leading, spacing: 20) {
                    if let element = input.dayElement {
                        HStack(spacing: 8) {
                            Image(systemName: elementIcon(for: element))
                                .font(.system(size: 18))
                                .foregroundColor(accent.opacity(0.7))
                            Text(element.uppercased())
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .tracking(1.5)
                                .foregroundColor(accent.opacity(0.55))
                        }
                    }

                    Text(input.insightText)
                        .font(.system(size: 21, weight: .regular))
                        .foregroundColor(accent)
                        .lineSpacing(7)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: false)

                    if let dynamic = input.dynamicText {
                        Text(dynamic)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(accent.opacity(0.65))
                            .lineSpacing(5)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: false)
                    }
                }
                .padding(.horizontal, 36)

                Spacer()

                // Bottom zone (~25%): watermark
                if input.includeBranding {
                    Text("inyon.app")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(accent.opacity(0.25))
                        .padding(.bottom, 48)
                }
            }
        }
    }
}
