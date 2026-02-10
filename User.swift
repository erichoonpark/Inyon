import Foundation
import FirebaseFirestore

struct User: Codable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String
    var birthDate: Date
    var birthTime: Date?
    var birthTimeUnknown: Bool
    var birthLocation: String
    var createdAt: Date

    init(
        id: String,
        firstName: String,
        lastName: String,
        email: String,
        birthDate: Date,
        birthTime: Date?,
        birthTimeUnknown: Bool,
        birthLocation: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.birthTimeUnknown = birthTimeUnknown
        self.birthLocation = birthLocation
        self.createdAt = createdAt
    }
}
