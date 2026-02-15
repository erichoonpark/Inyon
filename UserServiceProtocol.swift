import Foundation

protocol UserServiceProtocol {
    func createUser(_ user: User) async throws
    func fetchUser(id: String) async throws -> User?
    func updateUser(_ user: User) async throws
}
