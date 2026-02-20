import Foundation

@MainActor
protocol AuthServiceProtocol {
    var currentUserId: String? { get }
    var isAuthenticated: Bool { get }
    var isEmailVerified: Bool { get }
    func createAccount(email: String, password: String) async throws -> String
    func signIn(email: String, password: String) async throws
    func signOut() throws
    func sendPasswordReset(email: String) async throws
    func sendEmailVerification() async throws
    func reloadUser() async throws
}
