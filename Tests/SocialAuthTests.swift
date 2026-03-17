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

    func testSignInWithGoogleStartsSignedOut() {
        let mock = MockAuthService()
        XCTAssertNil(mock.currentUserId)
        XCTAssertFalse(mock.isAuthenticated)
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

// MARK: - Sequential Auth Attempts

@MainActor
final class SocialAuthSequenceTests: XCTestCase {

    func testGoogleFailureThenAppleSuccess() async throws {
        let mock = MockAuthService()
        mock.signInWithGoogleResult = .failure(MockError.forced)
        _ = try? await mock.signInWithGoogle()
        XCTAssertNil(mock.currentUserId, "currentUserId should remain nil after Google failure")

        mock.signInWithAppleResult = .success(())
        try await mock.signInWithApple(idToken: "tok", rawNonce: "nonce", fullName: nil)
        XCTAssertEqual(mock.currentUserId, "mock-uid")
    }

    func testAppleFailureThenGoogleSuccess() async throws {
        let mock = MockAuthService()
        mock.signInWithAppleResult = .failure(MockError.forced)
        _ = try? await mock.signInWithApple(idToken: "tok", rawNonce: "nonce", fullName: nil)
        XCTAssertNil(mock.currentUserId, "currentUserId should remain nil after Apple failure")

        mock.signInWithGoogleResult = .success(())
        try await mock.signInWithGoogle()
        XCTAssertEqual(mock.currentUserId, "mock-uid")
    }

    func testGoogleSuccessFollowedBySignOut() throws {
        let mock = MockAuthService()
        mock.signInWithGoogleResult = .success(())
        Task { try? await mock.signInWithGoogle() }

        mock.currentUserId = "mock-uid"  // simulate state after sign-in
        try mock.signOut()
        XCTAssertNil(mock.currentUserId)
    }

    func testAppleSuccessFollowedBySignOut() throws {
        let mock = MockAuthService()
        mock.currentUserId = "mock-uid"  // simulate state after sign-in
        try mock.signOut()
        XCTAssertNil(mock.currentUserId)
        XCTAssertFalse(mock.isAuthenticated)
    }
}

// MARK: - SocialAuthError Messages

final class SocialAuthErrorTests: XCTestCase {

    func testAllErrorDescriptionsAreNonNil() {
        XCTAssertNotNil(SocialAuthError.missingClientID.errorDescription)
        XCTAssertNotNil(SocialAuthError.missingToken.errorDescription)
        XCTAssertNotNil(SocialAuthError.missingPresenter.errorDescription)
        XCTAssertNotNil(SocialAuthError.accountExistsWithDifferentCredential.errorDescription)
    }

    func testAllErrorDescriptionsAreNonEmpty() {
        XCTAssertFalse(SocialAuthError.missingClientID.errorDescription?.isEmpty ?? true)
        XCTAssertFalse(SocialAuthError.missingToken.errorDescription?.isEmpty ?? true)
        XCTAssertFalse(SocialAuthError.missingPresenter.errorDescription?.isEmpty ?? true)
        XCTAssertFalse(SocialAuthError.accountExistsWithDifferentCredential.errorDescription?.isEmpty ?? true)
    }

    func testAccountExistsErrorMentionsEmail() {
        // User needs to understand they should try a different sign-in method for this email
        let msg = SocialAuthError.accountExistsWithDifferentCredential.errorDescription ?? ""
        XCTAssertTrue(msg.contains("email"), "Error should mention email so user knows what to do")
    }

    func testMissingPresenterIsUserFriendly() {
        let msg = SocialAuthError.missingPresenter.errorDescription ?? ""
        XCTAssertTrue(msg.contains("try again"), "Error should suggest retrying")
    }
}

// MARK: - Name Population Logic

// Tests the display name splitting logic used in handleGoogleSignIn()
// and the PersonNameComponents mapping used in handleAppleSignIn().

final class SocialAuthNamePopulationTests: XCTestCase {

    // MARK: - Google display name splitting

    func testDisplayNameTwoWords_splitsIntoFirstAndLast() {
        let displayName = "Ji Yeon"
        let (first, last) = splitDisplayName(displayName)
        XCTAssertEqual(first, "Ji")
        XCTAssertEqual(last, "Yeon")
    }

    func testDisplayNameSingleWord_isFirstNameOnly() {
        let displayName = "Jiyeon"
        let (first, last) = splitDisplayName(displayName)
        XCTAssertEqual(first, "Jiyeon")
        XCTAssertEqual(last, "")
    }

    func testDisplayNameThreeWords_firstAndRemainderAsLast() {
        // maxSplits:1 keeps the rest of the name as lastName
        let displayName = "Ji Yeon Park"
        let (first, last) = splitDisplayName(displayName)
        XCTAssertEqual(first, "Ji")
        XCTAssertEqual(last, "Yeon Park")
    }

    func testDisplayNameEmpty_producesEmptyStrings() {
        let (first, last) = splitDisplayName("")
        XCTAssertEqual(first, "")
        XCTAssertEqual(last, "")
    }

    // MARK: - Apple PersonNameComponents mapping

    func testAppleFullName_populatesFirstAndLast() {
        var fullName = PersonNameComponents()
        fullName.givenName = "Ji"
        fullName.familyName = "Yeon"

        let (first, last) = extractAppleName(fullName)
        XCTAssertEqual(first, "Ji")
        XCTAssertEqual(last, "Yeon")
    }

    func testAppleFullNameGivenOnly_lastIsEmpty() {
        var fullName = PersonNameComponents()
        fullName.givenName = "Jiyeon"
        fullName.familyName = nil

        let (first, last) = extractAppleName(fullName)
        XCTAssertEqual(first, "Jiyeon")
        XCTAssertEqual(last, "")
    }

    func testAppleNilFullName_producesEmptyStrings() {
        let fullName: PersonNameComponents? = nil
        let (first, last) = extractAppleName(fullName)
        XCTAssertEqual(first, "")
        XCTAssertEqual(last, "")
    }

    func testAppleFullNameFamilyOnly_firstIsEmpty() {
        var fullName = PersonNameComponents()
        fullName.givenName = nil
        fullName.familyName = "Park"

        let (first, last) = extractAppleName(fullName)
        XCTAssertEqual(first, "")
        XCTAssertEqual(last, "Park")
    }

    // MARK: - Helpers (mirror the exact logic from AccountCreationView handlers)

    private func splitDisplayName(_ displayName: String) -> (first: String, last: String) {
        let parts = displayName.split(separator: " ", maxSplits: 1)
        let first = parts.first.map(String.init) ?? ""
        let last = parts.dropFirst().first.map(String.init) ?? ""
        return (first, last)
    }

    private func extractAppleName(_ fullName: PersonNameComponents?) -> (first: String, last: String) {
        return (fullName?.givenName ?? "", fullName?.familyName ?? "")
    }
}

// MARK: - OnboardingData Social Fields

final class OnboardingDataSocialTests: XCTestCase {

    func testSocialFieldsDefaultToEmpty() {
        let data = OnboardingData()
        XCTAssertEqual(data.firstName, "")
        XCTAssertEqual(data.lastName, "")
        XCTAssertEqual(data.email, "")
    }

    func testSocialFieldsPopulatedFromGoogle() {
        var data = OnboardingData()
        // Mirrors handleGoogleSignIn population
        let displayName = "Ji Yeon"
        let parts = displayName.split(separator: " ", maxSplits: 1)
        data.firstName = parts.first.map(String.init) ?? ""
        data.lastName = parts.dropFirst().first.map(String.init) ?? ""
        data.email = "jiyeon@example.com"

        XCTAssertEqual(data.firstName, "Ji")
        XCTAssertEqual(data.lastName, "Yeon")
        XCTAssertEqual(data.email, "jiyeon@example.com")
    }

    func testSocialFieldsPopulatedFromApple() {
        var data = OnboardingData()
        var fullName = PersonNameComponents()
        fullName.givenName = "Ji"
        fullName.familyName = "Yeon"

        // Mirrors handleAppleSignIn population
        data.firstName = fullName.givenName ?? ""
        data.lastName = fullName.familyName ?? ""
        data.email = "jiyeon@privaterelay.appleid.com"

        XCTAssertEqual(data.firstName, "Ji")
        XCTAssertEqual(data.lastName, "Yeon")
        XCTAssertEqual(data.email, "jiyeon@privaterelay.appleid.com")
    }

    func testSocialFieldsIncludedInFirestorePayload() {
        var data = OnboardingData()
        data.firstName = "Ji"
        data.lastName = "Yeon"
        data.email = "jiyeon@example.com"

        let payload = data.toFirestoreData()
        XCTAssertEqual(payload["firstName"] as? String, "Ji")
        XCTAssertEqual(payload["lastName"] as? String, "Yeon")
        XCTAssertEqual(payload["email"] as? String, "jiyeon@example.com")
    }

    func testEmptySocialFieldsExcludedFromFirestorePayload() {
        let data = OnboardingData()
        let payload = data.toFirestoreData()

        XCTAssertNil(payload["firstName"], "Empty firstName should not appear in payload")
        XCTAssertNil(payload["lastName"], "Empty lastName should not appear in payload")
        XCTAssertNil(payload["email"], "Empty email should not appear in payload")
    }
}

// MARK: - Email Fallback Flag

final class SocialAuthEmailFallbackTests: XCTestCase {

    func testEmailFallbackFlagIsEnabled() {
        // This flag gates the "Use email instead" button during the social auth migration.
        // It must remain true until the team decides to cut over.
        XCTAssertTrue(enableEmailPasswordAuthFallback, "Email fallback must stay enabled until cutover")
    }
}
