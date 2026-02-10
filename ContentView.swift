import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            LensView()
                .tabItem {
                    Label("Lens", systemImage: "circle.hexagongrid")
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
