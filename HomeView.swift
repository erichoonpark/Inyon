import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var authService: AuthService
    private let today = Date()
    @State private var renderedShareCard: ShareableCard?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Logo header
                HStack(spacing: 8) {
                    Image("InyonLogo")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text("INYON")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .tracking(1.5)
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()
                }

                // Date header
                VStack(alignment: .leading, spacing: 4) {
                    Text(today.formatted(.dateTime.weekday(.wide)))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .tracking(1.2)
                        .foregroundColor(AppTheme.textSecondary)
                        .textCase(.uppercase)

                    Text(today.formatted(.dateTime.month(.wide).day()))
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }

                // Content based on state
                switch viewModel.state {
                case .idle, .loading:
                    loadingContent
                case .ready:
                    if let insight = viewModel.currentInsight {
                        insightContent(insight)
                    }
                case .error:
                    if let stale = viewModel.lastKnownInsight {
                        insightContent(stale)
                        retryBar
                    } else {
                        errorContent
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppTheme.earth)
        .task {
            viewModel.loadTodayInsight()
        }
        .task(id: viewModel.currentInsight?.insightText) {
            guard let insight = viewModel.currentInsight else { return }
            if let img = try? ShareCardRenderer().render(input: ShareCardInput.from(insight)).0 {
                renderedShareCard = ShareableCard(image: img)
            }
        }
        .task(id: viewModel.lastKnownInsight?.insightText) {
            guard renderedShareCard == nil, let insight = viewModel.lastKnownInsight else { return }
            if let img = try? ShareCardRenderer().render(input: ShareCardInput.from(insight)).0 {
                renderedShareCard = ShareableCard(image: img)
            }
        }
    }

    // MARK: - Insight Content

    private func insightContent(_ insight: DailyInsight) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            // Reflection text — lead with the actual content
            Text(insight.insightText)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(AppTheme.textPrimary)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)

            // Dynamic bridge — why this lands for you today (no label)
            if let dynamicText = insight.dynamicText, !dynamicText.isEmpty {
                Text(dynamicText)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.textPrimary.opacity(0.6))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Compact context card: element + stem/branch
            VStack(alignment: .leading, spacing: 12) {
                Text("CONDITIONS")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(1.5)
                    .foregroundColor(AppTheme.textSecondary)

                HStack(alignment: .center, spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: elementIcon(for: insight.dayElement))
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.textPrimary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(insight.dayElement)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)

                            Text(insight.elementTheme)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Rectangle()
                        .fill(AppTheme.divider)
                        .frame(width: 1, height: 36)
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("THE DAY")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .tracking(0.8)
                                .foregroundColor(AppTheme.textSecondary.opacity(0.7))
                            Text(simplifiedStemBranch(insight.heavenlyStem))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("YOUR NATURE")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .tracking(0.8)
                                .foregroundColor(AppTheme.textSecondary.opacity(0.7))
                            Text(simplifiedStemBranch(insight.earthlyBranch))
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.divider, lineWidth: 1)
                )
            }

            // Five Elements strip
            FiveElementsStrip(activeElement: insight.dayElement)

            // Share — ambient icon, no label, no border
            if let card = renderedShareCard {
                HStack {
                    Spacer()
                    ShareLink(
                        item: card,
                        preview: SharePreview(
                            "Today's reflection from Inyon",
                            image: Image(uiImage: card.image)
                        )
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .light))
                            .foregroundColor(AppTheme.textSecondary)
                            .opacity(0.5)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Loading Content

    private var loadingContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Reflection text placeholder — matches new leading position
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.surface)
                    .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22)
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.surface)
                    .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22)
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.surface)
                    .frame(maxWidth: 220, minHeight: 22, maxHeight: 22)
            }

            // Context card placeholder
            VStack(alignment: .leading, spacing: 12) {
                placeholderBar(width: 120)
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.surface)
                    .frame(height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.divider, lineWidth: 1)
                    )
            }

            // Elements strip placeholder
            VStack(alignment: .leading, spacing: 12) {
                placeholderBar(width: 80)
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.surface)
                    .frame(height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.divider, lineWidth: 1)
                    )
            }
        }
        .shimmer()
    }

    private func placeholderBar(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(AppTheme.surface)
            .frame(maxWidth: width == .infinity ? .infinity : width, minHeight: 14, maxHeight: 14)
    }

    // MARK: - Error Content

    private var errorContent: some View {
        VStack(spacing: 16) {
            Text("Unable to load today's reflection.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(AppTheme.textSecondary)

            Button {
                viewModel.retry()
            } label: {
                Text("Try Again")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.textPrimary.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 40)
    }

    // MARK: - Retry Bar (for stale content)

    private var retryBar: some View {
        HStack(spacing: 8) {
            Text("Showing a previous reflection.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppTheme.textSecondary)

            Spacer()

            Button {
                viewModel.retry()
            } label: {
                Text("Retry")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .underline()
            }
        }
        .padding(12)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Helpers

    /// Strips Korean parenthetical from stem/branch strings.
    /// e.g. "Gab (甲)" → "Gab"
    private func simplifiedStemBranch(_ raw: String) -> String {
        if let idx = raw.firstIndex(of: "(") {
            return String(raw[..<idx]).trimmingCharacters(in: .whitespaces)
        }
        return raw
    }

    private func elementIcon(for element: String) -> String {
        switch element.lowercased() {
        case "wood": return "leaf"
        case "fire": return "flame"
        case "earth": return "mountain.2"
        case "metal": return "circle.hexagongrid"
        case "water": return "drop"
        default: return "circle"
        }
    }
}

// MARK: - Five Elements Strip

struct FiveElementsStrip: View {
    var activeElement: String? = nil

    private let elements = [
        ("Wood", "leaf"),
        ("Fire", "flame"),
        ("Earth", "mountain.2"),
        ("Metal", "circle.hexagongrid"),
        ("Water", "drop")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ELEMENTS")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .tracking(1.5)
                .foregroundColor(AppTheme.textSecondary)

            HStack(spacing: 0) {
                ForEach(elements, id: \.0) { element in
                    let isActive = element.0.lowercased() == activeElement?.lowercased()
                    VStack(spacing: 6) {
                        Image(systemName: element.1)
                            .font(.system(size: isActive ? 22 : 16))
                            .foregroundColor(AppTheme.textPrimary)

                        Text(element.0.uppercased())
                            .font(.system(size: 10, weight: isActive ? .semibold : .regular, design: .monospaced))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(isActive ? 1.0 : 0.25)
                }
            }
            .padding(.vertical, 16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.divider, lineWidth: 1)
            )
        }
    }
}

// MARK: - Shimmer

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            AppTheme.textPrimary.opacity(0.06),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: phase * geo.size.width * 2)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

private extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthService())
}
