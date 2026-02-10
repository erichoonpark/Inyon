import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            GuideView()
                .tabItem {
                    Label("Guide", systemImage: "book")
                }

            YouView()
                .tabItem {
                    Label("You", systemImage: "person")
                }
        }
    }
}

#Preview {
    ContentView()
}
