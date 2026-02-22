import SwiftUI
import FirebaseCore

@main
struct InyonApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var appState = AppState()
    @AppStorage("inyon.hasSeenPostSignup") private var hasSeenPostSignup = false
    @Environment(\.scenePhase) private var scenePhase
    private let onboardingService: OnboardingServiceProtocol = OnboardingService()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    // Branded loading screen
                    VStack(spacing: 16) {
                        Spacer()
                        Image("InyonLogo")
                            .resizable()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        Text("INYON")
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(AppTheme.textPrimary)
                        ProgressView()
                            .tint(AppTheme.textSecondary)
                            .padding(.top, 8)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.earth.ignoresSafeArea())
                } else if let userId = authService.currentUserId {
                    if !hasSeenPostSignup {
                        PostSignupView {
                            hasSeenPostSignup = true
                        }
                    } else {
                        ContentView(onboardingService: onboardingService)
                            .environmentObject(appState)
                            .environmentObject(authService)
                            .task {
                                await appState.loadUser(id: userId)
                            }
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
            .onChange(of: authService.currentUserId) { _, newValue in
                if newValue == nil {
                    appState.clearUser()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { try? await authService.reloadUser() }
                }
            }
        }
    }
}
