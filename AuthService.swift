import Foundation
import FirebaseAuth

enum AuthServiceError: LocalizedError {
    case forcedUITestSignInFailure
    case forcedUITestSignOutFailure

    var errorDescription: String? {
        switch self {
        case .forcedUITestSignInFailure:
            return "Unable to sign in. Check your credentials and try again."
        case .forcedUITestSignOutFailure:
            return "Unable to log out. Please try again."
        }
    }
}

@MainActor
final class AuthService: ObservableObject, AuthServiceProtocol {
    @Published var currentUserId: String?
    @Published var isLoading = true

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let uiTestAuthMode: String?

    init() {
        uiTestAuthMode = ProcessInfo.processInfo.environment["INYON_UI_TEST_AUTH_MODE"]
        if uiTestAuthMode != nil {
            // Modes that test authenticated flows start signed in
            if uiTestAuthMode == "signed_in" || uiTestAuthMode == "sign_out_failure" {
                currentUserId = "ui-test-user"
            } else {
                currentUserId = nil
            }
            isLoading = false
            return
        }

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUserId = user?.uid
            self?.isLoading = false
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    var isAuthenticated: Bool {
        currentUserId != nil
    }

    func createAccount(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user.uid
    }

    func signIn(email: String, password: String) async throws {
        if uiTestAuthMode == "sign_in_failure" {
            throw AuthServiceError.forcedUITestSignInFailure
        }
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signOut() throws {
        if uiTestAuthMode != nil {
            if uiTestAuthMode == "sign_out_failure" {
                throw AuthServiceError.forcedUITestSignOutFailure
            }
            currentUserId = nil
            return
        }
        try Auth.auth().signOut()
    }
}
