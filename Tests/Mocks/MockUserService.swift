import Foundation
@testable import Inyon

final class MockUserService: UserServiceProtocol {
    // Call recording
    var createdUsers: [User] = []
    var fetchedIds: [String] = []
    var updatedUsers: [User] = []

    // Controllable results
    var fetchResult: Result<User?, Error> = .success(nil)
    var createResult: Result<Void, Error> = .success(())
    var updateResult: Result<Void, Error> = .success(())

    func createUser(_ user: User) async throws {
        switch createResult {
        case .success:
            createdUsers.append(user)
        case .failure(let error):
            throw error
        }
    }

    func fetchUser(id: String) async throws -> User? {
        fetchedIds.append(id)
        switch fetchResult {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
    }

    func updateUser(_ user: User) async throws {
        switch updateResult {
        case .success:
            updatedUsers.append(user)
        case .failure(let error):
            throw error
        }
    }
}
