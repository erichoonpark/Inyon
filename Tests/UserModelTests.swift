import XCTest
@testable import Inyon

// MARK: - User Model Tests
//
// Tests the User struct: initialization, property values,
// and edge cases for optional fields.

final class UserModelTests: XCTestCase {

    // MARK: - Initialization

    func test_init_setsAllRequiredFields() {
        let date = Date()
        let user = User(
            id: "user-1",
            firstName: "Minjun",
            lastName: "Kim",
            email: "minjun@example.com",
            birthDate: date,
            birthTime: nil,
            birthTimeUnknown: true,
            birthLocation: "Seoul, South Korea"
        )

        XCTAssertEqual(user.id, "user-1")
        XCTAssertEqual(user.firstName, "Minjun")
        XCTAssertEqual(user.lastName, "Kim")
        XCTAssertEqual(user.email, "minjun@example.com")
        XCTAssertEqual(user.birthDate, date)
        XCTAssertNil(user.birthTime)
        XCTAssertTrue(user.birthTimeUnknown)
        XCTAssertEqual(user.birthLocation, "Seoul, South Korea")
    }

    func test_init_withBirthTime() {
        let date = Date()
        let time = Date()
        let user = User(
            id: "user-2",
            firstName: "Jiyeon",
            lastName: "Park",
            email: "jiyeon@example.com",
            birthDate: date,
            birthTime: time,
            birthTimeUnknown: false,
            birthLocation: "Busan, South Korea"
        )

        XCTAssertEqual(user.birthTime, time)
        XCTAssertFalse(user.birthTimeUnknown)
    }

    func test_init_createdAtDefaultsToNow() {
        let before = Date()
        let user = User(
            id: "user-3",
            firstName: "Test",
            lastName: "User",
            email: "test@example.com",
            birthDate: Date(),
            birthTime: nil,
            birthTimeUnknown: false,
            birthLocation: "Tokyo, Japan"
        )
        let after = Date()

        XCTAssertGreaterThanOrEqual(user.createdAt, before)
        XCTAssertLessThanOrEqual(user.createdAt, after)
    }

    func test_init_createdAtCanBeOverridden() {
        let customDate = Date(timeIntervalSince1970: 1000000)
        let user = User(
            id: "user-4",
            firstName: "Test",
            lastName: "User",
            email: "test@example.com",
            birthDate: Date(),
            birthTime: nil,
            birthTimeUnknown: false,
            birthLocation: "Incheon, South Korea",
            createdAt: customDate
        )

        XCTAssertEqual(user.createdAt, customDate)
    }

    // MARK: - Mutability

    func test_mutableFields_canBeUpdated() {
        var user = User(
            id: "user-5",
            firstName: "Original",
            lastName: "Name",
            email: "original@example.com",
            birthDate: Date(),
            birthTime: nil,
            birthTimeUnknown: true,
            birthLocation: "Seoul, South Korea"
        )

        user.firstName = "Updated"
        user.lastName = "NewName"
        user.email = "updated@example.com"
        user.birthLocation = "Busan, South Korea"

        XCTAssertEqual(user.firstName, "Updated")
        XCTAssertEqual(user.lastName, "NewName")
        XCTAssertEqual(user.email, "updated@example.com")
        XCTAssertEqual(user.birthLocation, "Busan, South Korea")
    }

    func test_birthTime_canBeSetAfterCreation() {
        var user = User(
            id: "user-6",
            firstName: "Test",
            lastName: "User",
            email: "test@example.com",
            birthDate: Date(),
            birthTime: nil,
            birthTimeUnknown: true,
            birthLocation: "Seoul, South Korea"
        )

        XCTAssertNil(user.birthTime)
        XCTAssertTrue(user.birthTimeUnknown)

        let time = Date()
        user.birthTime = time
        user.birthTimeUnknown = false

        XCTAssertEqual(user.birthTime, time)
        XCTAssertFalse(user.birthTimeUnknown)
    }

    func test_birthTime_canBeCleared() {
        var user = User(
            id: "user-7",
            firstName: "Test",
            lastName: "User",
            email: "test@example.com",
            birthDate: Date(),
            birthTime: Date(),
            birthTimeUnknown: false,
            birthLocation: "Seoul, South Korea"
        )

        XCTAssertNotNil(user.birthTime)

        user.birthTime = nil
        user.birthTimeUnknown = true

        XCTAssertNil(user.birthTime)
        XCTAssertTrue(user.birthTimeUnknown)
    }

    // MARK: - ID Immutability

    func test_id_isImmutable() {
        let user = User(
            id: "user-8",
            firstName: "Test",
            lastName: "User",
            email: "test@example.com",
            birthDate: Date(),
            birthTime: nil,
            birthTimeUnknown: false,
            birthLocation: "Seoul, South Korea"
        )

        // id is declared as `let`, so this is a compile-time guarantee.
        // We verify the value is set correctly.
        XCTAssertEqual(user.id, "user-8")
    }
}
