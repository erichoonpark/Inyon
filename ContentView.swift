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
    var body: some View {
        RootTabView()
    }
}

// MARK: - Root Tab View

struct RootTabView: View {
    @State private var selectedTab: Tab = .home

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                case .home: HomeView()
                case .guide: GuideView()
                case .you: YouView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.earth)

            CustomBottomNav(selectedTab: $selectedTab)
        }
        .background(AppTheme.earth)
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Custom Bottom Nav

struct CustomBottomNav: View {
    @Binding var selectedTab: Tab
    @Namespace private var underlineNamespace

    var body: some View {
        HStack {
            ForEach(Tab.allCases) { tab in
                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .tracking(1.2)
                            .foregroundColor(AppTheme.textPrimary)
                            .opacity(selectedTab == tab ? 1.0 : 0.45)

                        ZStack {
                            if selectedTab == tab {
                                Rectangle()
                                    .fill(AppTheme.underline.opacity(0.95))
                                    .frame(width: 18, height: 1)
                                    .matchedGeometryEffect(id: "underline", in: underlineNamespace)
                            } else {
                                Color.clear.frame(height: 1)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                Spacer()
            }
        }
        .frame(height: 60)
        .background(
            AppTheme.earth
                .overlay(AppTheme.surface)
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(AppTheme.divider),
            alignment: .top
        )
    }
}

#Preview {
    ContentView()
}
