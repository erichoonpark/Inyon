import Foundation
import FirebaseAuth

@MainActor
final class AuthService: ObservableObject, AuthServiceProtocol {
    @Published var currentUserId: String?
    @Published var isLoading = true

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
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
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
