import XCTest
@testable import Inyon

@MainActor
final class SocialAuthTests: XCTestCase {

    // MARK: - Google Sign-In

    func testSignInWithGoogleSuccess() async throws {
        let mock = MockAuthService()
        mock.signInWithGoogleResult = .success(())
        try await mock.signInWithGoogle()
        XCTAssertEqual(mock.signInWithGoogleCallCount, 1)
        XCTAssertEqual(mock.currentUserId, "mock-uid")
    }

    func testSignInWithGoogleFailure() async {
        let mock = MockAuthService()
        mock.signInWithGoogleResult = .failure(MockError.forced)
        do {
            try await mock.signInWithGoogle()
            XCTFail("Expected throw")
        } catch {
            XCTAssertNil(mock.currentUserId)
            XCTAssertEqual(mock.signInWithGoogleCallCount, 1)
        }
    }

    func testSignInWithGoogleRecordsEachCall() async {
        let mock = MockAuthService()
        _ = try? await mock.signInWithGoogle()
        _ = try? await mock.signInWithGoogle()
        XCTAssertEqual(mock.signInWithGoogleCallCount, 2)
    }

    // MARK: - Apple Sign-In

    func testSignInWithAppleSuccess() async throws {
        let mock = MockAuthService()
        mock.signInWithAppleResult = .success(())
        try await mock.signInWithApple(idToken: "test-token", rawNonce: "test-nonce", fullName: nil)
        XCTAssertEqual(mock.signInWithAppleCalls.count, 1)
        XCTAssertEqual(mock.signInWithAppleCalls[0].idToken, "test-token")
        XCTAssertEqual(mock.signInWithAppleCalls[0].rawNonce, "test-nonce")
        XCTAssertEqual(mock.currentUserId, "mock-uid")
    }

    func testSignInWithAppleFailure() async {
        let mock = MockAuthService()
        mock.signInWithAppleResult = .failure(MockError.forced)
        do {
            try await mock.signInWithApple(idToken: "tok", rawNonce: "nonce", fullName: nil)
            XCTFail("Expected throw")
        } catch {
            XCTAssertNil(mock.currentUserId)
            XCTAssertEqual(mock.signInWithAppleCalls.count, 1)
        }
    }

    func testSignInWithApplePassesFullName() async throws {
        let mock = MockAuthService()
        var name = PersonNameComponents()
        name.givenName = "Ji"
        name.familyName = "Yeon"
        try await mock.signInWithApple(idToken: "tok", rawNonce: "nonce", fullName: name)
        XCTAssertEqual(mock.signInWithAppleCalls.count, 1)
        XCTAssertEqual(mock.currentUserId, "mock-uid")
    }

    func testSignInWithAppleAcceptsNilFullName() async throws {
        let mock = MockAuthService()
        // Subsequent Apple sign-ins return nil fullName — must be handled
        try await mock.signInWithApple(idToken: "tok", rawNonce: "nonce", fullName: nil)
        XCTAssertEqual(mock.currentUserId, "mock-uid")
    }
}
