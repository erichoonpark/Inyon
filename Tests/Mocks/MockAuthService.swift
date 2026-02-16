import Foundation
@testable import Inyon

enum MockError: Error {
    case forced
}

@MainActor
final class MockAuthService: AuthServiceProtocol {
    var currentUserId: String?
    var isAuthenticated: Bool { currentUserId != nil }

    // Call recording
    var createAccountCalls: [(email: String, password: String)] = []
    var signInCalls: [(email: String, password: String)] = []
    var signOutCallCount = 0

    // Controllable results
    var createAccountResult: Result<String, Error> = .success("mock-uid")
    var signInResult: Result<Void, Error> = .success(())
    var signOutResult: Result<Void, Error> = .success(())

    /// When false, createAccount returns the uid but does NOT update currentUserId,
    /// simulating the real AuthService race where the auth state listener hasn't fired yet.
    var autoUpdateAuthState: Bool = true

    func createAccount(email: String, password: String) async throws -> String {
        createAccountCalls.append((email, password))
        switch createAccountResult {
        case .success(let uid):
            if autoUpdateAuthState {
                currentUserId = uid
            }
            return uid
        case .failure(let error):
            throw error
        }
    }

    func signIn(email: String, password: String) async throws {
        signInCalls.append((email, password))
        switch signInResult {
        case .success:
            currentUserId = "mock-uid"
        case .failure(let error):
            throw error
        }
    }

    func signOut() throws {
        signOutCallCount += 1
        switch signOutResult {
        case .success:
            currentUserId = nil
        case .failure(let error):
            throw error
        }
    }
}
