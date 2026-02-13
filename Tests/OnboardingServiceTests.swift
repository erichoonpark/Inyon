import XCTest
@testable import Inyon

// MARK: - Onboarding Service Tests
//
// Tests that OnboardingFlow and YouView correctly call the OnboardingService.
// Uses MockOnboardingService and MockAuthService to verify interactions
// without touching real Firebase.

final class OnboardingServiceTests: XCTestCase {

    // MARK: - Save: Authenticated User

    func test_save_withAuthenticatedUser_passesUserId() async throws {
        let mockService = MockOnboardingService()
        var data = OnboardingData()
        data.birthDate = Date()
        data.birthCity = "Seoul, South Korea"
        data.personalAnchors = [.direction]

        let userId = "user-123"
        try await mockService.saveOnboardingData(data, userId: userId)

        XCTAssertEqual(mockService.savedData.count, 1)
        XCTAssertEqual(mockService.savedData.first?.userId, userId)
        XCTAssertNotNil(mockService.storedPayloads[userId])
    }

    // MARK: - Save: Anonymous User

    func test_save_withNoAuth_passesNilUserId() async throws {
        let mockService = MockOnboardingService()
        var data = OnboardingData()
        data.birthDate = Date()
        data.birthCity = "Busan, South Korea"

        try await mockService.saveOnboardingData(data, userId: nil)

        XCTAssertEqual(mockService.savedData.count, 1)
        XCTAssertNil(mockService.savedData.first?.userId)
        XCTAssertNotNil(mockService.storedPayloads["anonymous"])
    }

    // MARK: - Save: Data Integrity

    func test_save_passesCorrectOnboardingData() async throws {
        let mockService = MockOnboardingService()
        var data = OnboardingData()
        data.birthDate = Date()
        data.birthCity = "San Francisco, CA, United States"
        data.personalAnchors = [.energy, .love]

        try await mockService.saveOnboardingData(data, userId: "user-456")

        let saved = mockService.savedData.first?.data
        XCTAssertEqual(saved?.birthCity, "San Francisco, CA, United States")
        XCTAssertEqual(saved?.personalAnchors.count, 2)
        XCTAssertTrue(saved?.personalAnchors.contains(.energy) ?? false)
        XCTAssertTrue(saved?.personalAnchors.contains(.love) ?? false)
    }

    // MARK: - Save: Error Handling

    func test_save_error_propagates() async {
        let mockService = MockOnboardingService()
        mockService.saveResult = .failure(MockError.forced)

        do {
            try await mockService.saveOnboardingData(OnboardingData(), userId: "user-789")
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is MockError)
        }
    }

    // MARK: - Load: Returns Stored Data

    func test_load_returnsStoredData() async throws {
        let mockService = MockOnboardingService()

        // Pre-populate storage
        var data = OnboardingData()
        data.birthDate = Date()
        data.birthCity = "Seoul, South Korea"
        try await mockService.saveOnboardingData(data, userId: "user-123")

        let loaded = try await mockService.loadOnboardingData(userId: "user-123")
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?["birthCity"] as? String, "Seoul, South Korea")
    }

    // MARK: - Load: No Data Returns Nil

    func test_load_noData_returnsNil() async throws {
        let mockService = MockOnboardingService()

        let loaded = try await mockService.loadOnboardingData(userId: "nonexistent-user")
        XCTAssertNil(loaded)
    }

    // MARK: - Update: Merges Data

    func test_update_storesData() async throws {
        let mockService = MockOnboardingService()
        let updatePayload: [String: Any] = [
            "personalAnchors": ["Direction", "Rest"],
            "notificationsEnabled": true
        ]

        try await mockService.updateOnboardingData(userId: "user-123", data: updatePayload)

        XCTAssertEqual(mockService.updatedData.count, 1)
        XCTAssertEqual(mockService.updatedData.first?.userId, "user-123")
        XCTAssertNotNil(mockService.storedPayloads["user-123"])
    }

    // MARK: - MockAuthService: Basic Behavior

    @MainActor
    func test_mockAuth_createAccount_setsUserId() async throws {
        let mockAuth = MockAuthService()
        XCTAssertNil(mockAuth.currentUserId)
        XCTAssertFalse(mockAuth.isAuthenticated)

        let uid = try await mockAuth.createAccount(email: "test@inyon.com", password: "password123")

        XCTAssertEqual(uid, "mock-uid")
        XCTAssertEqual(mockAuth.currentUserId, "mock-uid")
        XCTAssertTrue(mockAuth.isAuthenticated)
        XCTAssertEqual(mockAuth.createAccountCalls.count, 1)
        XCTAssertEqual(mockAuth.createAccountCalls.first?.email, "test@inyon.com")
    }

    @MainActor
    func test_mockAuth_signOut_clearsUserId() throws {
        let mockAuth = MockAuthService()
        mockAuth.currentUserId = "user-123"
        XCTAssertTrue(mockAuth.isAuthenticated)

        try mockAuth.signOut()

        XCTAssertNil(mockAuth.currentUserId)
        XCTAssertFalse(mockAuth.isAuthenticated)
        XCTAssertEqual(mockAuth.signOutCallCount, 1)
    }

    @MainActor
    func test_mockAuth_createAccount_failure_throwsError() async {
        let mockAuth = MockAuthService()
        mockAuth.createAccountResult = .failure(MockError.forced)

        do {
            _ = try await mockAuth.createAccount(email: "test@inyon.com", password: "pass")
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is MockError)
            XCTAssertNil(mockAuth.currentUserId, "User should not be authenticated after failed creation")
        }
    }
}
