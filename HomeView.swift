import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    private let today = Date()

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
    }

    // MARK: - Insight Content

    private func insightContent(_ insight: DailyInsight) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            // Day Element card
            VStack(alignment: .leading, spacing: 12) {
                Text("DAY ELEMENT")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(1.5)
                    .foregroundColor(AppTheme.textSecondary)

                HStack(spacing: 12) {
                    Image(systemName: elementIcon(for: insight.dayElement))
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.textPrimary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.dayElement)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)

                        Text(insight.elementTheme)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }

            // Stem Pair
            VStack(alignment: .leading, spacing: 12) {
                Text("STEM & BRANCH")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(1.5)
                    .foregroundColor(AppTheme.textSecondary)

                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Heavenly Stem")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .tracking(1)
                            .foregroundColor(AppTheme.textSecondary)

                        Text(insight.heavenlyStem)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Earthly Branch")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .tracking(1)
                            .foregroundColor(AppTheme.textSecondary)

                        Text(insight.earthlyBranch)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.divider, lineWidth: 1)
                )
            }

            // Five Elements strip (highlight active)
            FiveElementsStrip(activeElement: insight.dayElement)

            // Daily insight text
            VStack(alignment: .leading, spacing: 12) {
                Text("TODAY")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(1.5)
                    .foregroundColor(AppTheme.textSecondary)

                Text(insight.insightText)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Loading Content

    private var loadingContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Day Element placeholder
            VStack(alignment: .leading, spacing: 12) {
                placeholderBar(width: 100)
                HStack(spacing: 12) {
                    Circle()
                        .fill(AppTheme.surface)
                        .frame(width: 24, height: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        placeholderBar(width: 80)
                        placeholderBar(width: 140)
                    }
                }
            }

            // Stem pair placeholder
            VStack(alignment: .leading, spacing: 12) {
                placeholderBar(width: 120)
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.surface)
                    .frame(height: 70)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.divider, lineWidth: 1)
                    )
            }

            // Insight placeholder
            VStack(alignment: .leading, spacing: 12) {
                placeholderBar(width: 60)
                placeholderBar(width: .infinity)
                placeholderBar(width: .infinity)
                placeholderBar(width: 200)
            }
        }
        .redacted(reason: .placeholder)
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

    private func elementIcon(for element: String) -> String {
        switch element.lowercased() {
        case "wood": return "leaf"
        case "fire": return "flame"
        case "earth": return "square.on.square"
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
        ("Earth", "square.on.square"),
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
                            .font(.system(size: 16))
                            .foregroundColor(isActive ? AppTheme.textPrimary : AppTheme.textSecondary)

                        Text(element.0)
                            .font(.system(size: 10, weight: isActive ? .semibold : .medium))
                            .foregroundColor(isActive ? AppTheme.textPrimary : AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
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

#Preview {
    HomeView()
}
