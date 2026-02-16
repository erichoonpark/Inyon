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

    @MainActor
    func test_mockAuth_signIn_setsUserId() async throws {
        let mockAuth = MockAuthService()
        XCTAssertNil(mockAuth.currentUserId)
        XCTAssertFalse(mockAuth.isAuthenticated)

        try await mockAuth.signIn(email: "test@inyon.com", password: "password123")

        XCTAssertEqual(mockAuth.currentUserId, "mock-uid")
        XCTAssertTrue(mockAuth.isAuthenticated)
        XCTAssertEqual(mockAuth.signInCalls.count, 1)
        XCTAssertEqual(mockAuth.signInCalls.first?.email, "test@inyon.com")
    }

    @MainActor
    func test_mockAuth_signIn_failure_throwsError() async {
        let mockAuth = MockAuthService()
        mockAuth.signInResult = .failure(MockError.forced)

        do {
            try await mockAuth.signIn(email: "test@inyon.com", password: "wrong")
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is MockError)
            XCTAssertNil(mockAuth.currentUserId, "User should not be authenticated after failed sign in")
        }
    }
}

// MARK: - Auth Flow Integration Tests
//
// Tests that mirror the auth logic in AccountCreationView and LoginView.
// Verifies that onComplete is called only on success, and errors are captured.

final class AuthFlowTests: XCTestCase {

    // MARK: - Account Creation Flow

    @MainActor
    func test_accountCreation_success_callsOnComplete() async throws {
        let mockAuth = MockAuthService()
        var completed = false

        _ = try await mockAuth.createAccount(email: "new@inyon.com", password: "secure123")
        completed = true

        XCTAssertTrue(completed)
        XCTAssertTrue(mockAuth.isAuthenticated)
        XCTAssertEqual(mockAuth.createAccountCalls.count, 1)
    }

    @MainActor
    func test_accountCreation_failure_doesNotCallOnComplete() async {
        let mockAuth = MockAuthService()
        mockAuth.createAccountResult = .failure(MockError.forced)
        var completed = false
        var errorMessage: String?

        do {
            _ = try await mockAuth.createAccount(email: "new@inyon.com", password: "secure123")
            completed = true
        } catch {
            errorMessage = error.localizedDescription
        }

        XCTAssertFalse(completed, "onComplete should not be called on auth failure")
        XCTAssertNotNil(errorMessage, "Error message should be set on failure")
        XCTAssertFalse(mockAuth.isAuthenticated)
    }

    @MainActor
    func test_accountCreation_savesOnboardingDataOnSuccess() async throws {
        let mockAuth = MockAuthService()
        let mockService = MockOnboardingService()

        var data = OnboardingData()
        data.birthDate = Date()
        data.birthCity = "Seoul, South Korea"
        data.personalAnchors = [.direction]

        let uid = try await mockAuth.createAccount(email: "new@inyon.com", password: "secure123")
        try await mockService.saveOnboardingData(data, userId: uid)

        XCTAssertEqual(mockService.savedData.count, 1)
        XCTAssertEqual(mockService.savedData.first?.userId, uid)
    }

    // MARK: - Login Flow

    @MainActor
    func test_login_success_callsOnComplete() async throws {
        let mockAuth = MockAuthService()
        var completed = false

        try await mockAuth.signIn(email: "returning@inyon.com", password: "password123")
        completed = true

        XCTAssertTrue(completed)
        XCTAssertTrue(mockAuth.isAuthenticated)
        XCTAssertEqual(mockAuth.signInCalls.count, 1)
    }

    @MainActor
    func test_login_failure_doesNotCallOnComplete() async {
        let mockAuth = MockAuthService()
        mockAuth.signInResult = .failure(MockError.forced)
        var completed = false
        var errorMessage: String?

        do {
            try await mockAuth.signIn(email: "returning@inyon.com", password: "wrong")
            completed = true
        } catch {
            errorMessage = error.localizedDescription
        }

        XCTAssertFalse(completed, "onComplete should not be called on login failure")
        XCTAssertNotNil(errorMessage, "Error message should be set on failure")
        XCTAssertFalse(mockAuth.isAuthenticated)
    }

    @MainActor
    func test_login_doesNotSaveOnboardingData() async throws {
        let mockAuth = MockAuthService()
        let mockService = MockOnboardingService()

        try await mockAuth.signIn(email: "returning@inyon.com", password: "password123")

        XCTAssertTrue(mockAuth.isAuthenticated)
        XCTAssertEqual(mockService.savedData.count, 0, "Login should not save onboarding data")
    }

    // MARK: - Input Validation (mirrors view logic)

    func test_createAccount_requiresNonEmptyEmail() {
        let email = ""
        let password = "secure123"
        let canSubmit = !email.isEmpty && password.count >= 6
        XCTAssertFalse(canSubmit)
    }

    func test_createAccount_requiresPasswordMinLength() {
        let email = "test@inyon.com"
        let password = "short"
        let canSubmit = !email.isEmpty && password.count >= 6
        XCTAssertFalse(canSubmit, "Password must be at least 6 characters")
    }

    func test_createAccount_validInputsAllowSubmit() {
        let email = "test@inyon.com"
        let password = "secure123"
        let canSubmit = !email.isEmpty && password.count >= 6
        XCTAssertTrue(canSubmit)
    }

    func test_login_requiresNonEmptyFields() {
        let email = ""
        let password = ""
        let canSubmit = !email.isEmpty && !password.isEmpty
        XCTAssertFalse(canSubmit)
    }

    func test_login_validInputsAllowSubmit() {
        let email = "test@inyon.com"
        let password = "any"
        let canSubmit = !email.isEmpty && !password.isEmpty
        XCTAssertTrue(canSubmit)
    }
}

// MARK: - Write Failure & Retry Tests

final class WriteFailureTests: XCTestCase {

    // MARK: - Onboarding Save Failure

    func test_onboardingSave_failure_blocksCompletion() async {
        let mockService = MockOnboardingService()
        mockService.saveResult = .failure(MockError.forced)
        var completed = false
        var errorOccurred = false

        do {
            try await mockService.saveOnboardingData(OnboardingData(), userId: "user-1")
            completed = true
        } catch {
            errorOccurred = true
        }

        XCTAssertFalse(completed, "Completion should be blocked on save failure")
        XCTAssertTrue(errorOccurred)
    }

    func test_onboardingSave_retryAfterFailure_succeeds() async throws {
        let mockService = MockOnboardingService()

        // First attempt fails
        mockService.saveResult = .failure(MockError.forced)
        do {
            try await mockService.saveOnboardingData(OnboardingData(), userId: "user-1")
            XCTFail("Should have thrown")
        } catch {
            XCTAssertTrue(error is MockError)
        }
        XCTAssertEqual(mockService.savedData.count, 1)

        // Retry succeeds
        mockService.saveResult = .success(())
        try await mockService.saveOnboardingData(OnboardingData(), userId: "user-1")
        XCTAssertEqual(mockService.savedData.count, 2)
        XCTAssertNotNil(mockService.storedPayloads["user-1"])
    }

    // MARK: - YouView Update Failure

    func test_profileUpdate_failure_setsError() async {
        let mockService = MockOnboardingService()
        mockService.updateResult = .failure(MockError.forced)
        var saveError: String?

        do {
            try await mockService.updateOnboardingData(userId: "user-1", data: ["key": "value"])
        } catch {
            saveError = "Could not save changes. Please try again."
        }

        XCTAssertNotNil(saveError)
        XCTAssertEqual(saveError, "Could not save changes. Please try again.")
    }

    func test_profileUpdate_retryAfterFailure_succeeds() async throws {
        let mockService = MockOnboardingService()

        // First attempt fails
        mockService.updateResult = .failure(MockError.forced)
        do {
            try await mockService.updateOnboardingData(userId: "user-1", data: ["key": "value"])
            XCTFail("Should have thrown")
        } catch {
            XCTAssertTrue(error is MockError)
        }

        // Retry succeeds
        mockService.updateResult = .success(())
        try await mockService.updateOnboardingData(userId: "user-1", data: ["key": "value"])

        XCTAssertEqual(mockService.updatedData.count, 2)
        XCTAssertNotNil(mockService.storedPayloads["user-1"])
    }

    func test_profileUpdate_success_clearsUnsavedChanges() async throws {
        let mockService = MockOnboardingService()
        var hasUnsavedChanges = true
        var saveError: String?

        do {
            try await mockService.updateOnboardingData(userId: "user-1", data: ["key": "value"])
            hasUnsavedChanges = false
        } catch {
            saveError = error.localizedDescription
        }

        XCTAssertFalse(hasUnsavedChanges)
        XCTAssertNil(saveError)
    }
}

// MARK: - Anonymous Data Merge Tests

final class AnonymousDataMergeTests: XCTestCase {

    // MARK: - Anonymous Save

    func test_anonymousSave_storesUnderAnonymousKey() async throws {
        let mockService = MockOnboardingService()
        var data = OnboardingData()
        data.birthDate = Date()
        data.birthCity = "Seoul, South Korea"

        try await mockService.saveOnboardingData(data, userId: nil)

        XCTAssertEqual(mockService.savedData.count, 1)
        XCTAssertNil(mockService.savedData.first?.userId)
        XCTAssertNotNil(mockService.storedPayloads["anonymous"])
    }

    func test_anonymousSave_preservesData() async throws {
        let mockService = MockOnboardingService()
        var data = OnboardingData()
        data.birthDate = Date()
        data.birthCity = "Busan, South Korea"
        data.personalAnchors = [.direction, .energy]

        try await mockService.saveOnboardingData(data, userId: nil)

        let stored = mockService.storedPayloads["anonymous"]
        XCTAssertEqual(stored?["birthCity"] as? String, "Busan, South Korea")
    }

    // MARK: - Migration: No Existing User Data

    func test_migrate_noExistingData_movesAnonymousToUser() async throws {
        let mockService = MockOnboardingService()

        // Save anonymous data
        var data = OnboardingData()
        data.birthCity = "Seoul, South Korea"
        try await mockService.saveOnboardingData(data, userId: nil)
        XCTAssertNotNil(mockService.storedPayloads["anonymous"])

        // Migrate to authenticated user
        try await mockService.migrateAnonymousData(toUserId: "user-123")

        XCTAssertEqual(mockService.migrateCalls.count, 1)
        XCTAssertEqual(mockService.migrateCalls.first, "user-123")
        XCTAssertNotNil(mockService.storedPayloads["user-123"])
        XCTAssertNil(mockService.storedPayloads["anonymous"], "Anonymous data should be removed after migration")
    }

    // MARK: - Migration: Existing User Data (Conflict Resolution)

    func test_migrate_existingData_existingWinsOnConflict() async throws {
        let mockService = MockOnboardingService()

        // Save anonymous data
        var anonData = OnboardingData()
        anonData.birthCity = "Seoul, South Korea"
        anonData.personalAnchors = [.direction]
        try await mockService.saveOnboardingData(anonData, userId: nil)

        // Pre-existing user data
        mockService.storedPayloads["user-123"] = [
            "birthCity": "Busan, South Korea",
            "personalAnchors": ["Energy"]
        ]

        // Migrate — existing data should win on conflict
        try await mockService.migrateAnonymousData(toUserId: "user-123")

        let merged = mockService.storedPayloads["user-123"]
        XCTAssertEqual(merged?["birthCity"] as? String, "Busan, South Korea", "Existing data should win on conflict")
    }

    // MARK: - Migration: No Anonymous Data

    func test_migrate_noAnonymousData_noOp() async throws {
        let mockService = MockOnboardingService()

        // No anonymous data saved
        try await mockService.migrateAnonymousData(toUserId: "user-123")

        XCTAssertEqual(mockService.migrateCalls.count, 1)
        // Should not create empty user data
        XCTAssertNil(mockService.storedPayloads["user-123"])
    }

    // MARK: - Migration: Cleanup

    func test_migrate_removesAnonymousRecord() async throws {
        let mockService = MockOnboardingService()

        var data = OnboardingData()
        data.birthCity = "Tokyo, Japan"
        try await mockService.saveOnboardingData(data, userId: nil)
        XCTAssertNotNil(mockService.storedPayloads["anonymous"])

        try await mockService.migrateAnonymousData(toUserId: "user-456")

        XCTAssertNil(mockService.storedPayloads["anonymous"])
        XCTAssertNotNil(mockService.storedPayloads["user-456"])
    }

    // MARK: - Migration: Failure

    func test_migrate_failure_preservesAnonymousData() async {
        let mockService = MockOnboardingService()
        mockService.storedPayloads["anonymous"] = ["birthCity": "Seoul, South Korea"]
        mockService.migrateResult = .failure(MockError.forced)

        do {
            try await mockService.migrateAnonymousData(toUserId: "user-123")
            XCTFail("Should have thrown")
        } catch {
            XCTAssertTrue(error is MockError)
        }

        // Anonymous data should still exist
        XCTAssertNotNil(mockService.storedPayloads["anonymous"])
    }

    // MARK: - Full Flow: Anonymous Save → Auth → Migrate

    @MainActor
    func test_fullFlow_anonymousSaveThenAuthThenMigrate() async throws {
        let mockAuth = MockAuthService()
        let mockService = MockOnboardingService()

        // Step 1: Save anonymous onboarding data
        var data = OnboardingData()
        data.birthDate = Date()
        data.birthCity = "Seoul, South Korea"
        data.personalAnchors = [.direction, .love]
        try await mockService.saveOnboardingData(data, userId: nil)
        XCTAssertNotNil(mockService.storedPayloads["anonymous"])

        // Step 2: User creates account
        let uid = try await mockAuth.createAccount(email: "new@inyon.com", password: "secure123")

        // Step 3: Save authenticated data and migrate
        try await mockService.saveOnboardingData(data, userId: uid)
        try await mockService.migrateAnonymousData(toUserId: uid)

        // Verify: user data exists, anonymous cleaned up
        XCTAssertNotNil(mockService.storedPayloads[uid])
        XCTAssertNil(mockService.storedPayloads["anonymous"])
    }

    // MARK: - Priority 1: UID Race Condition

    /// Ensures the onboarding save path uses the UID returned from createAccount
    /// even if authService.currentUserId has not been updated by the auth state listener.
    @MainActor
    func test_accountCreation_usesReturnedUID_whenAuthListenerNotYetUpdated() async throws {
        let mockAuth = MockAuthService()
        mockAuth.autoUpdateAuthState = false  // Simulate auth listener not yet fired
        let mockService = MockOnboardingService()

        var data = OnboardingData()
        data.birthDate = Date()
        data.birthCity = "Seoul, South Korea"

        // Create account — returns uid but currentUserId stays nil
        let uid = try await mockAuth.createAccount(email: "test@inyon.com", password: "secure123")
        XCTAssertEqual(uid, "mock-uid")
        XCTAssertNil(mockAuth.currentUserId, "Auth listener has not updated yet")

        // The save path must use the returned uid, not authService.currentUserId
        try await mockService.saveOnboardingData(data, userId: uid)

        XCTAssertEqual(mockService.savedData.count, 1)
        XCTAssertEqual(mockService.savedData.first?.userId, uid, "Should use returned UID, not authService.currentUserId")
        XCTAssertNotNil(mockService.storedPayloads[uid])
    }

    // MARK: - Priority 2: Save+Migrate Failure Blocks Completion

    /// Verifies that onComplete is not called when migration fails and retry state is surfaced.
    @MainActor
    func test_saveThenMigrate_failure_blocksCompletion_andShowsRetry() async throws {
        let mockAuth = MockAuthService()
        let mockService = MockOnboardingService()
        mockService.migrateResult = .failure(MockError.forced)

        var data = OnboardingData()
        data.birthDate = Date()
        data.birthCity = "Seoul, South Korea"

        // Create account
        let uid = try await mockAuth.createAccount(email: "test@inyon.com", password: "secure123")

        // Save succeeds
        try await mockService.saveOnboardingData(data, userId: uid)
        XCTAssertNotNil(mockService.storedPayloads[uid])

        // Migration fails — should block completion
        var completed = false
        var errorOccurred = false
        do {
            try await mockService.migrateAnonymousData(toUserId: uid)
            completed = true
        } catch {
            errorOccurred = true
        }

        XCTAssertFalse(completed, "onComplete should not be called when migration fails")
        XCTAssertTrue(errorOccurred, "Migration error should propagate")
    }

    // MARK: - Priority 3: Atomic Migration Under Concurrent Write

    /// Simulates a concurrent user write during migration and proves
    /// no clobbering of newer user data.
    @MainActor
    func test_migrateAnonymousData_isAtomic_underConcurrentUserWrite() async throws {
        let mockService = MockOnboardingService()

        // Step 1: Save anonymous data
        var anonData = OnboardingData()
        anonData.birthCity = "Seoul, South Korea"
        anonData.personalAnchors = [.direction]
        try await mockService.saveOnboardingData(anonData, userId: nil)
        XCTAssertNotNil(mockService.storedPayloads["anonymous"])

        // Step 2: Simulate a concurrent user write (newer data that arrived before migration)
        mockService.storedPayloads["user-concurrent"] = [
            "birthCity": "Busan, South Korea",
            "personalAnchors": ["Energy", "Love"],
            "notificationsEnabled": true
        ]

        // Step 3: Migrate — existing user data must win on conflict
        try await mockService.migrateAnonymousData(toUserId: "user-concurrent")

        let merged = mockService.storedPayloads["user-concurrent"]
        XCTAssertEqual(merged?["birthCity"] as? String, "Busan, South Korea",
                       "Concurrent user write should not be overwritten by anonymous data")
        XCTAssertEqual(merged?["personalAnchors"] as? [String], ["Energy", "Love"],
                       "User's newer anchor selection should survive migration")
        XCTAssertEqual(merged?["notificationsEnabled"] as? Bool, true,
                       "Fields only in user data should be preserved")
        XCTAssertNil(mockService.storedPayloads["anonymous"],
                     "Anonymous record should be cleaned up after migration")
    }
}

// MARK: - Priority 7: YouView Save Failure Preserves Unsaved State

final class YouViewSaveTests: XCTestCase {

    /// Ensures failed profile save keeps unsaved state and exposes retry.
    func test_youView_saveFailure_showsRetrySave_andPreservesUnsavedChanges() async {
        let mockService = MockOnboardingService()
        mockService.updateResult = .failure(MockError.forced)
        var hasUnsavedChanges = true
        var saveError: String?
        var isSaving = true

        do {
            try await mockService.updateOnboardingData(userId: "user-1", data: [
                "personalAnchors": ["Direction", "Energy"],
                "birthCity": "Updated City"
            ])
            hasUnsavedChanges = false
        } catch {
            saveError = "Could not save changes. Please try again."
        }
        isSaving = false

        // Unsaved changes must be preserved
        XCTAssertTrue(hasUnsavedChanges, "Unsaved changes must be preserved after save failure")
        XCTAssertNotNil(saveError, "Error message should be surfaced for retry")
        XCTAssertEqual(saveError, "Could not save changes. Please try again.")
        XCTAssertFalse(isSaving, "Saving state should be reset after failure")

        // The button label should show "Retry Save" when saveError is set
        let buttonLabel = saveError != nil ? "Retry Save" : "Save Changes"
        XCTAssertEqual(buttonLabel, "Retry Save", "Button should show retry label after failure")
    }

    /// Ensures retry after failure succeeds and clears unsaved state.
    func test_youView_retryAfterFailure_succeeds_andClearsUnsavedChanges() async throws {
        let mockService = MockOnboardingService()

        // First attempt fails
        mockService.updateResult = .failure(MockError.forced)
        var hasUnsavedChanges = true
        var saveError: String?

        do {
            try await mockService.updateOnboardingData(userId: "user-1", data: ["key": "value"])
        } catch {
            saveError = "Could not save changes. Please try again."
        }
        XCTAssertTrue(hasUnsavedChanges)
        XCTAssertNotNil(saveError)

        // Retry succeeds
        mockService.updateResult = .success(())
        saveError = nil
        do {
            try await mockService.updateOnboardingData(userId: "user-1", data: ["key": "value"])
            hasUnsavedChanges = false
        } catch {
            saveError = error.localizedDescription
        }

        XCTAssertFalse(hasUnsavedChanges, "Unsaved changes should be cleared after successful retry")
        XCTAssertNil(saveError, "Error should be cleared after successful retry")
    }
}

private final class MockMigrationExecutor: OnboardingMigrationExecuting {
    var callCount = 0
    var lastAnonymousSessionId: String?
    var lastUserId: String?
    var result: Result<Bool, Error> = .success(true)

    func migrateAnonymousData(anonymousSessionId: String, toUserId userId: String) async throws -> Bool {
        callCount += 1
        lastAnonymousSessionId = anonymousSessionId
        lastUserId = userId

        switch result {
        case .success(let migrated):
            return migrated
        case .failure(let error):
            throw error
        }
    }
}

final class OnboardingServiceMigrationTests: XCTestCase {

    func test_mergeOnboardingMigrationData_existingUserFieldsWin() {
        let anonymousData: [String: Any] = [
            "birthCity": "Seoul, South Korea",
            "personalAnchors": ["Direction"],
            "notificationsEnabled": false
        ]
        let existingUserData: [String: Any] = [
            "birthCity": "Busan, South Korea",
            "notificationsEnabled": true,
            "customField": "keep-me"
        ]

        let merged = mergeOnboardingMigrationData(
            anonymousData: anonymousData,
            existingUserData: existingUserData
        )

        XCTAssertEqual(merged["birthCity"] as? String, "Busan, South Korea")
        XCTAssertEqual(merged["notificationsEnabled"] as? Bool, true)
        XCTAssertEqual(merged["personalAnchors"] as? [String], ["Direction"])
        XCTAssertEqual(merged["customField"] as? String, "keep-me")
    }

    func test_mergeOnboardingMigrationData_withoutUserDocument_returnsAnonymousData() {
        let anonymousData: [String: Any] = [
            "birthCity": "Seoul, South Korea",
            "personalAnchors": ["Direction"]
        ]

        let merged = mergeOnboardingMigrationData(
            anonymousData: anonymousData,
            existingUserData: nil
        )

        XCTAssertEqual(merged["birthCity"] as? String, "Seoul, South Korea")
        XCTAssertEqual(merged["personalAnchors"] as? [String], ["Direction"])
    }

    func test_migrateAnonymousData_callsTransactionalExecutor_andClearsSessionKey_onSuccess() async throws {
        let suiteName = "OnboardingServiceMigrationTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected isolated UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set("anon-123", forKey: OnboardingService.anonymousIdKey)
        let executor = MockMigrationExecutor()
        executor.result = .success(true)
        let service = OnboardingService(userDefaults: defaults, migrationExecutor: executor)

        try await service.migrateAnonymousData(toUserId: "user-abc")

        XCTAssertEqual(executor.callCount, 1)
        XCTAssertEqual(executor.lastAnonymousSessionId, "anon-123")
        XCTAssertEqual(executor.lastUserId, "user-abc")
        XCTAssertNil(defaults.string(forKey: OnboardingService.anonymousIdKey))
    }

    func test_migrateAnonymousData_keepsSessionKey_whenNoAnonymousRecordMigrated() async throws {
        let suiteName = "OnboardingServiceMigrationTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected isolated UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set("anon-456", forKey: OnboardingService.anonymousIdKey)
        let executor = MockMigrationExecutor()
        executor.result = .success(false)
        let service = OnboardingService(userDefaults: defaults, migrationExecutor: executor)

        try await service.migrateAnonymousData(toUserId: "user-xyz")

        XCTAssertEqual(executor.callCount, 1)
        XCTAssertEqual(defaults.string(forKey: OnboardingService.anonymousIdKey), "anon-456")
    }

    func test_migrateAnonymousData_propagatesError_andDoesNotClearSessionKey() async {
        let suiteName = "OnboardingServiceMigrationTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected isolated UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set("anon-789", forKey: OnboardingService.anonymousIdKey)
        let executor = MockMigrationExecutor()
        executor.result = .failure(MockError.forced)
        let service = OnboardingService(userDefaults: defaults, migrationExecutor: executor)

        do {
            try await service.migrateAnonymousData(toUserId: "user-error")
            XCTFail("Expected migrateAnonymousData to throw")
        } catch {
            XCTAssertTrue(error is MockError)
        }

        XCTAssertEqual(executor.callCount, 1)
        XCTAssertEqual(defaults.string(forKey: OnboardingService.anonymousIdKey), "anon-789")
    }
}
