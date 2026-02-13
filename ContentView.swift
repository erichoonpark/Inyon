import SwiftUI

// MARK: - Tab Enum

enum Tab: String, CaseIterable, Identifiable {
    case home = "HOME"
    case guide = "GUIDE"
    case you = "YOU"

    var id: String { rawValue }
}

// MARK: - Content View (Root)

struct ContentView: View {
    let onboardingService: OnboardingServiceProtocol

    var body: some View {
        RootTabView(onboardingService: onboardingService)
    }
}

// MARK: - Root Tab View

struct RootTabView: View {
    let onboardingService: OnboardingServiceProtocol
    @State private var selectedTab: Tab = .home

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .home: HomeView()
                case .guide: GuideView()
                case .you: YouView(onboardingService: onboardingService)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CustomBottomNav(selectedTab: $selectedTab)
        }
        .background(AppTheme.earth.ignoresSafeArea())
    }
}

// MARK: - Custom Bottom Nav

struct CustomBottomNav: View {
    @Binding var selectedTab: Tab
    @Namespace private var underlineNamespace

    var body: some View {
        GeometryReader { geo in
            let itemWidth = geo.size.width / CGFloat(Tab.allCases.count)

            HStack(spacing: 0) {
                ForEach(Tab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .tracking(1.2)
                                .foregroundColor(AppTheme.textOnRedPrimary)
                                .opacity(selectedTab == tab ? 1.0 : 0.55)

                            ZStack {
                                // Reserve underline space ALWAYS
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 18, height: 1)

                                if selectedTab == tab {
                                    Rectangle()
                                        .fill(AppTheme.textOnRedPrimary)
                                        .frame(width: 18, height: 1)
                                        .matchedGeometryEffect(
                                            id: "underline",
                                            in: underlineNamespace
                                        )
                                }
                            }
                        }
                        .frame(width: itemWidth, height: 60)
                        .contentShape(Rectangle())
                    }
                }
            }
            .background(
                AppTheme.earthRed
                    .ignoresSafeArea(edges: .bottom)
            )
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(AppTheme.dividerOnRed),
                alignment: .top
            )
        }
        .frame(height: 60)
    }
}

#Preview {
    ContentView(onboardingService: OnboardingService())
}
