import XCTest
@testable import Inyon

// MARK: - AppState Tests
//
// Tests the AppState observable object: loadUser flow,
// loading states, and error handling.
// Uses MockUserService to avoid hitting Firebase.

final class AppStateTests: XCTestCase {

    // MARK: - Initial State

    @MainActor
    func test_initialState_noUser() {
        let appState = AppState(userService: MockUserService())

        XCTAssertNil(appState.currentUser)
        XCTAssertFalse(appState.isLoadingUser)
    }

    // MARK: - Load User: Success

    @MainActor
    func test_loadUser_success_setsCurrentUser() async {
        let mockService = MockUserService()
        let expectedUser = User(
            id: "user-1",
            firstName: "Minjun",
            lastName: "Kim",
            email: "minjun@example.com",
            birthDate: Date(),
            birthTime: nil,
            birthTimeUnknown: true,
            birthLocation: "Seoul, South Korea"
        )
        mockService.fetchResult = .success(expectedUser)

        let appState = AppState(userService: mockService)
        await appState.loadUser(id: "user-1")

        XCTAssertNotNil(appState.currentUser)
        XCTAssertEqual(appState.currentUser?.id, "user-1")
        XCTAssertEqual(appState.currentUser?.firstName, "Minjun")
        XCTAssertFalse(appState.isLoadingUser)
    }

    @MainActor
    func test_loadUser_passesCorrectId() async {
        let mockService = MockUserService()
        let appState = AppState(userService: mockService)

        await appState.loadUser(id: "user-abc")

        XCTAssertEqual(mockService.fetchedIds, ["user-abc"])
    }

    // MARK: - Load User: Not Found

    @MainActor
    func test_loadUser_notFound_currentUserRemainsNil() async {
        let mockService = MockUserService()
        mockService.fetchResult = .success(nil)

        let appState = AppState(userService: mockService)
        await appState.loadUser(id: "nonexistent")

        XCTAssertNil(appState.currentUser)
        XCTAssertFalse(appState.isLoadingUser)
    }

    // MARK: - Load User: Error

    @MainActor
    func test_loadUser_error_currentUserRemainsNil() async {
        let mockService = MockUserService()
        mockService.fetchResult = .failure(MockError.forced)

        let appState = AppState(userService: mockService)
        await appState.loadUser(id: "user-1")

        XCTAssertNil(appState.currentUser, "User should be nil after fetch error")
        XCTAssertFalse(appState.isLoadingUser, "Loading should be false after error")
    }

    // MARK: - Loading State

    @MainActor
    func test_loadUser_setsLoadingFalseAfterCompletion() async {
        let mockService = MockUserService()
        let appState = AppState(userService: mockService)

        await appState.loadUser(id: "user-1")

        XCTAssertFalse(appState.isLoadingUser)
    }

    @MainActor
    func test_loadUser_setsLoadingFalseAfterError() async {
        let mockService = MockUserService()
        mockService.fetchResult = .failure(MockError.forced)

        let appState = AppState(userService: mockService)
        await appState.loadUser(id: "user-1")

        XCTAssertFalse(appState.isLoadingUser)
    }

    // MARK: - Replacing User

    @MainActor
    func test_loadUser_replacesExistingUser() async {
        let mockService = MockUserService()
        let firstUser = User(
            id: "user-1",
            firstName: "First",
            lastName: "User",
            email: "first@example.com",
            birthDate: Date(),
            birthTime: nil,
            birthTimeUnknown: false,
            birthLocation: "Seoul, South Korea"
        )
        let secondUser = User(
            id: "user-2",
            firstName: "Second",
            lastName: "User",
            email: "second@example.com",
            birthDate: Date(),
            birthTime: nil,
            birthTimeUnknown: false,
            birthLocation: "Busan, South Korea"
        )

        let appState = AppState(userService: mockService)

        mockService.fetchResult = .success(firstUser)
        await appState.loadUser(id: "user-1")
        XCTAssertEqual(appState.currentUser?.id, "user-1")

        mockService.fetchResult = .success(secondUser)
        await appState.loadUser(id: "user-2")
        XCTAssertEqual(appState.currentUser?.id, "user-2")
    }
}

// MARK: - Auth State Routing Tests
//
// Tests the view-routing logic from InyonApp:
// nil userId → onboarding, non-nil userId → content view with loadUser.

final class AuthStateRoutingTests: XCTestCase {

    @MainActor
    func test_nilUserId_showsOnboarding() {
        let mockAuth = MockAuthService()
        mockAuth.currentUserId = nil

        // Mirrors InyonApp: `if let userId = authService.currentUserId` fails
        XCTAssertNil(mockAuth.currentUserId)
        XCTAssertFalse(mockAuth.isAuthenticated)
    }

    @MainActor
    func test_nonNilUserId_showsContentView() {
        let mockAuth = MockAuthService()
        mockAuth.currentUserId = "user-123"

        // Mirrors InyonApp: `if let userId = authService.currentUserId` succeeds
        if let userId = mockAuth.currentUserId {
            XCTAssertEqual(userId, "user-123")
        } else {
            XCTFail("userId should not be nil when authenticated")
        }
    }

    @MainActor
    func test_authStateChange_fromNilToAuthenticated() async throws {
        let mockAuth = MockAuthService()
        XCTAssertNil(mockAuth.currentUserId)

        try await mockAuth.signIn(email: "test@inyon.com", password: "password")

        // After sign-in, userId should be available for routing
        XCTAssertNotNil(mockAuth.currentUserId)
        if let userId = mockAuth.currentUserId {
            XCTAssertEqual(userId, "mock-uid")
        }
    }

    @MainActor
    func test_authStateChange_fromAuthenticatedToNil() throws {
        let mockAuth = MockAuthService()
        mockAuth.currentUserId = "user-123"

        try mockAuth.signOut()

        // After sign-out, should route back to onboarding
        XCTAssertNil(mockAuth.currentUserId)
        XCTAssertFalse(mockAuth.isAuthenticated)
    }
}
