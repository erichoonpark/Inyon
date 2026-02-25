import SwiftUI
import os.log

// MARK: - Style Constants

enum GuideStyle {
    static let cardRadius: CGFloat = 16
    static let cardPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 16
    static let horizontalPadding: CGFloat = 20

    static var accentGreen: Color {
        AppTheme.textPrimary
    }

    static var cardBackground: Color {
        AppTheme.surface
    }

    static var cardBorder: Color {
        AppTheme.divider
    }
}

// MARK: - Section Card View

struct SectionCardView<Content: View>: View {
    let iconName: String
    let title: String
    let summary: String
    let learnMoreBullets: [String]
    let additionalContent: Content?

    init(
        iconName: String,
        title: String,
        summary: String,
        learnMoreBullets: [String] = [],
        @ViewBuilder additionalContent: () -> Content = { EmptyView() }
    ) {
        self.iconName = iconName
        self.title = title
        self.summary = summary
        self.learnMoreBullets = learnMoreBullets
        self.additionalContent = additionalContent()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(GuideStyle.accentGreen)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(title)

            // Summary
            Text(summary)
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            // Additional content slot
            if Content.self != EmptyView.self {
                additionalContent
            }

            // Learn more disclosure
            if !learnMoreBullets.isEmpty {
                LearnMoreDisclosure(bullets: learnMoreBullets)
            }
        }
        .padding(GuideStyle.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GuideStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: GuideStyle.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: GuideStyle.cardRadius)
                .stroke(GuideStyle.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Learn More Disclosure

struct LearnMoreDisclosure: View {
    let bullets: [String]
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
                GuideAnalytics.trackSectionExpanded(isExpanded: isExpanded)
            } label: {
                HStack {
                    Text("Learn more")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(GuideStyle.accentGreen)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .accessibilityLabel(isExpanded ? "Learn more, expanded" : "Learn more, collapsed")
            .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(GuideStyle.accentGreen.opacity(0.6))
                                .frame(width: 6, height: 6)
                                .padding(.top, 7)
                                .accessibilityHidden(true)

                            Text(bullet)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Element Grid View

struct ElementGridView: View {
    let elements: [ElementItem]
    @State private var selectedElement: ElementItem?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(elements) { element in
                ElementChip(element: element)
                    .onTapGesture {
                        selectedElement = element
                        GuideAnalytics.trackElementOpened(element.name)
                    }
                    .accessibilityLabel("\(element.name): \(element.shortDesc)")
                    .accessibilityHint("Double tap for more details")
                    .accessibilityAddTraits(.isButton)
            }
        }
        .sheet(item: $selectedElement) { element in
            ElementDetailSheet(element: element)
        }
    }
}

struct ElementChip: View {
    let element: ElementItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: element.iconName)
                    .font(.body)
                    .foregroundStyle(GuideStyle.accentGreen)

                Text(element.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Text(element.shortDesc)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(GuideStyle.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Element Detail Sheet

struct ElementDetailSheet: View {
    let element: ElementItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack(spacing: 12) {
                        Image(systemName: element.iconName)
                            .font(.title)
                            .foregroundStyle(GuideStyle.accentGreen)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(element.name)
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text(element.shortDesc)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(element.detailBullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(GuideStyle.accentGreen)
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 6)

                                Text(bullet)
                                    .font(.body)
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Is / Is Not Card

struct IsIsNotCard: View {
    let isItems: [IsIsNotItem]
    let isNotItems: [IsIsNotItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "checkmark.shield")
                    .font(.title3)
                    .foregroundStyle(GuideStyle.accentGreen)

                Text("What Saju Is / Is Not")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textPrimary)
            }

            // Two columns
            HStack(alignment: .top, spacing: 16) {
                // Is column
                VStack(alignment: .leading, spacing: 12) {
                    Text("Saju Is")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(GuideStyle.accentGreen)

                    ForEach(isItems, id: \.text) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundStyle(GuideStyle.accentGreen)
                                .padding(.top, 2)

                            Text(item.text)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Divider
                Rectangle()
                    .fill(GuideStyle.cardBorder)
                    .frame(width: 1)

                // Is Not column
                VStack(alignment: .leading, spacing: 12) {
                    Text("Saju Is Not")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.textSecondary)

                    ForEach(isNotItems, id: \.text) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                                .padding(.top, 2)

                            Text(item.text)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(GuideStyle.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GuideStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: GuideStyle.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: GuideStyle.cardRadius)
                .stroke(GuideStyle.cardBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("What Saju is and is not")
    }
}

// MARK: - Analytics (Debug Stubs)

private let guideLogger = Logger(subsystem: "com.inyon.app", category: "Guide")

enum GuideAnalytics {
    static func trackGuideOpened() {
        guideLogger.debug("guide_opened")
    }

    static func trackSectionExpanded(isExpanded: Bool) {
        if isExpanded {
            guideLogger.debug("guide_section_expanded")
        }
    }

    static func trackElementOpened(_ name: String) {
        guideLogger.debug("element_opened: \(name)")
    }


}
