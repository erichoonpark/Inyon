import SwiftUI

struct GuideView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: GuideStyle.sectionSpacing) {
                    // A) What Is Saju?
                    SectionCardView(
                        iconName: GuideContent.whatIsSaju.iconName,
                        title: GuideContent.whatIsSaju.title,
                        summary: GuideContent.whatIsSaju.summary,
                        learnMoreBullets: GuideContent.whatIsSaju.learnMoreBullets
                    )

                    // B) How Saju Is Structured
                    SectionCardView(
                        iconName: GuideContent.howStructured.iconName,
                        title: GuideContent.howStructured.title,
                        summary: GuideContent.howStructured.summary,
                        learnMoreBullets: GuideContent.howStructured.learnMoreBullets
                    )

                    // C) The Five Elements
                    SectionCardView(
                        iconName: GuideContent.elementsSection.iconName,
                        title: GuideContent.elementsSection.title,
                        summary: GuideContent.elementsSection.summary,
                        learnMoreBullets: GuideContent.elementsSection.learnMoreBullets
                    ) {
                        ElementGridView(elements: GuideContent.elements)
                    }

                    // D) Reading a Chart
                    SectionCardView(
                        iconName: GuideContent.readingChart.iconName,
                        title: GuideContent.readingChart.title,
                        summary: GuideContent.readingChart.summary,
                        learnMoreBullets: GuideContent.readingChart.learnMoreBullets
                    )

                    // E) What Saju Is / Is Not
                    IsIsNotCard(
                        isItems: GuideContent.isItems,
                        isNotItems: GuideContent.isNotItems
                    )

                    // F) How Inyon Uses Saju
                    SectionCardView(
                        iconName: GuideContent.howInyonUses.iconName,
                        title: GuideContent.howInyonUses.title,
                        summary: GuideContent.howInyonUses.summary
                    ) {
                        ViewChartCTA()
                    }
                }
                .padding(.horizontal, GuideStyle.horizontalPadding)
                .padding(.vertical, 24)
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Guide")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            GuideAnalytics.trackGuideOpened()
        }
    }
}

#Preview {
    GuideView()
}
