import SwiftUI
import FirebaseCore

@main
struct InyonApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var appState = AppState()
    private let onboardingService: OnboardingServiceProtocol = OnboardingService()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    ProgressView()
                } else if authService.isAuthenticated {
                    ContentView(onboardingService: onboardingService)
                        .environmentObject(appState)
                        .task {
                            await appState.loadUser(id: authService.currentUserId!)
                        }
                } else {
                    OnboardingFlow(onboardingService: onboardingService, onComplete: {
                        // TODO: Handle auth completion
                        // For now, this will be handled by AuthService state changes
                    })
                    .environmentObject(authService)
                }
            }
            .environmentObject(authService)
        }
    }
}
