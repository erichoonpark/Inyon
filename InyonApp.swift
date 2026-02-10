import SwiftUI
import FirebaseCore

@main
struct InyonApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var appState = AppState()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    ProgressView()
                } else if authService.isAuthenticated {
                    ContentView()
                        .environmentObject(appState)
                        .task {
                            await appState.loadUser(id: authService.currentUserId!)
                        }
                } else {
                    SignupFlowView()
                        .environmentObject(authService)
                }
            }
            .environmentObject(authService)
        }
    }
}
