import Foundation
import FirebaseFirestore

final class UserService: UserServiceProtocol {
    private let db = Firestore.firestore()
    private let collection = "users"

    func createUser(_ user: User) async throws {
        try db.collection(collection).document(user.id).setData(from: user)
    }

    func fetchUser(id: String) async throws -> User? {
        let document = try await db.collection(collection).document(id).getDocument()
        return try document.data(as: User.self)
    }

    func updateUser(_ user: User) async throws {
        try db.collection(collection).document(user.id).setData(from: user, merge: true)
    }
}
