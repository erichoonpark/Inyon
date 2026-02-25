import XCTest
import FirebaseFirestore
@testable import Inyon

// MARK: - Helpers

@MainActor
private func makeViewModel(
    auth: MockAuthService? = nil,
    onboarding: MockOnboardingService? = nil,
    notifications: MockNotificationService? = nil
) -> YouViewModel {
    let mockAuth = auth ?? MockAuthService()
    let vm = YouViewModel(
        onboardingService: onboarding ?? MockOnboardingService(),
        notificationService: notifications ?? MockNotificationService()
    )
    vm.authService = mockAuth
    return vm
}

// MARK: - Load Tests

@MainActor
final class YouViewModel_LoadTests: XCTestCase {

    func test_loadData_noUserId_setsIsLoadingFalse() async {
        let auth = MockAuthService()
        auth.currentUserId = nil
        let vm = makeViewModel(auth: auth)

        await vm.loadData()

        XCTAssertFalse(vm.isLoading)
    }

    func test_loadData_noData_setsIsLoadingFalse() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        onboarding.loadResult = .success(nil)
        let vm = makeViewModel(auth: auth, onboarding: onboarding)

        await vm.loadData()

        XCTAssertFalse(vm.isLoading)
    }

    func test_loadData_serviceError_setsIsLoadingFalse() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        onboarding.loadResult = .failure(MockError.forced)
        let vm = makeViewModel(auth: auth, onboarding: onboarding)

        await vm.loadData()

        XCTAssertFalse(vm.isLoading)
    }

    func test_loadData_loadsFirstAndLastName() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        onboarding.loadResult = .success([
            "firstName": "Park",
            "lastName": "Eric"
        ])
        let vm = makeViewModel(auth: auth, onboarding: onboarding)

        await vm.loadData()

        XCTAssertEqual(vm.firstName, "Park")
        XCTAssertEqual(vm.lastName, "Eric")
    }

    func test_loadData_loadsBirthLocation() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        onboarding.loadResult = .success(["birthLocation": "Seoul, South Korea"])
        let vm = makeViewModel(auth: auth, onboarding: onboarding)

        await vm.loadData()

        XCTAssertEqual(vm.birthLocation, "Seoul, South Korea")
    }

    func test_loadData_mapsTimestampToBirthDate() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        let refDate = Date(timeIntervalSince1970: 946684800) // 2000-01-01
        onboarding.loadResult = .success(["birthDate": Timestamp(date: refDate)])
        let vm = makeViewModel(auth: auth, onboarding: onboarding)

        await vm.loadData()

        XCTAssertNotNil(vm.birthDate)
        XCTAssertEqual(vm.birthDate!.timeIntervalSince1970, refDate.timeIntervalSince1970, accuracy: 1)
        XCTAssertEqual(vm.selectedDate.timeIntervalSince1970, refDate.timeIntervalSince1970, accuracy: 1)
    }

    func test_loadData_setsHasSelectedDateFlag() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        onboarding.loadResult = .success(["birthDate": Timestamp(date: Date())])
        let vm = makeViewModel(auth: auth, onboarding: onboarding)

        await vm.loadData()

        XCTAssertTrue(vm.hasSelectedDate)
    }

    func test_loadData_mapsTimestampToBirthTime() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        let refTime = Date(timeIntervalSince1970: 946684800)
        onboarding.loadResult = .success(["birthTime": Timestamp(date: refTime)])
        let vm = makeViewModel(auth: auth, onboarding: onboarding)

        await vm.loadData()

        XCTAssertNotNil(vm.birthTime)
        XCTAssertEqual(vm.birthTime!.timeIntervalSince1970, refTime.timeIntervalSince1970, accuracy: 1)
        XCTAssertEqual(vm.selectedTime.timeIntervalSince1970, refTime.timeIntervalSince1970, accuracy: 1)
    }

    func test_loadData_setsHasSelectedTimeFlag() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        onboarding.loadResult = .success(["birthTime": Timestamp(date: Date())])
        let vm = makeViewModel(auth: auth, onboarding: onboarding)

        await vm.loadData()

        XCTAssertTrue(vm.hasSelectedTime)
    }

    func test_loadData_mapsStringArrayToPersonalAnchors() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        onboarding.loadResult = .success([
            "personalAnchors": ["Direction", "Energy"]
        ])
        let vm = makeViewModel(auth: auth, onboarding: onboarding)

        await vm.loadData()

        XCTAssertEqual(vm.personalAnchors.count, 2)
        XCTAssertTrue(vm.personalAnchors.contains(.direction))
        XCTAssertTrue(vm.personalAnchors.contains(.energy))
    }

    func test_loadData_unknownAnchorStrings_areDropped() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        onboarding.loadResult = .success([
            "personalAnchors": ["Direction", "NotARealAnchor", "Energy"]
        ])
        let vm = makeViewModel(auth: auth, onboarding: onboarding)

        await vm.loadData()

        XCTAssertEqual(vm.personalAnchors.count, 2, "Unknown anchors should be silently dropped")
    }

    func test_loadData_missingOptionalFields_leavesDefaults() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        // Minimal data — no optional fields
        onboarding.loadResult = .success(["firstName": "Test"])
        let vm = makeViewModel(auth: auth, onboarding: onboarding)

        await vm.loadData()

        XCTAssertNil(vm.birthDate)
        XCTAssertNil(vm.birthTime)
        XCTAssertTrue(vm.personalAnchors.isEmpty)
        XCTAssertFalse(vm.hasSelectedDate)
        XCTAssertFalse(vm.hasSelectedTime)
    }

    func test_loadData_resetsHasUnsavedChanges() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        onboarding.loadResult = .success(["firstName": "Test"])
        let vm = makeViewModel(auth: auth, onboarding: onboarding)
        vm.hasUnsavedChanges = true // Simulate pre-existing dirty state

        await vm.loadData()

        XCTAssertFalse(vm.hasUnsavedChanges, "Load should reset unsaved changes flag")
    }

    func test_loadData_loadsNotificationPreferences() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        let notifTime = Date(timeIntervalSince1970: 1700000000)
        onboarding.loadResult = .success([
            "notificationsEnabled": true,
            "preferredNotificationTime": Timestamp(date: notifTime)
        ])
        let vm = makeViewModel(auth: auth, onboarding: onboarding)

        await vm.loadData()

        XCTAssertTrue(vm.notificationsEnabled)
        XCTAssertEqual(
            vm.preferredNotificationTime.timeIntervalSince1970,
            notifTime.timeIntervalSince1970,
            accuracy: 1
        )
    }
}

// MARK: - Save Tests

@MainActor
final class YouViewModel_SaveTests: XCTestCase {

    func test_saveData_noOp_whenNoUserId() async {
        let auth = MockAuthService()
        auth.currentUserId = nil
        let onboarding = MockOnboardingService()
        let vm = makeViewModel(auth: auth, onboarding: onboarding)

        await vm.saveData()

        XCTAssertEqual(onboarding.updatedData.count, 0, "Should not call service without auth")
    }

    func test_saveData_callsUpdateWithCorrectUserId() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-42"
        let onboarding = MockOnboardingService()
        let vm = makeViewModel(auth: auth, onboarding: onboarding)

        await vm.saveData()

        XCTAssertEqual(onboarding.updatedData.first?.userId, "user-42")
    }

    func test_saveData_includesFirstAndLastName() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        let vm = makeViewModel(auth: auth, onboarding: onboarding)
        vm.firstName = "Eric"
        vm.lastName = "Park"

        await vm.saveData()

        let data = onboarding.updatedData.first!.data
        XCTAssertEqual(data["firstName"] as? String, "Eric")
        XCTAssertEqual(data["lastName"] as? String, "Park")
    }

    func test_saveData_includesBirthLocationWhenNonEmpty() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        let vm = makeViewModel(auth: auth, onboarding: onboarding)
        vm.birthLocation = "Seoul, South Korea"

        await vm.saveData()

        let data = onboarding.updatedData.first!.data
        XCTAssertEqual(data["birthLocation"] as? String, "Seoul, South Korea")
    }

    func test_saveData_deleteBirthLocationWhenEmpty() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        let vm = makeViewModel(auth: auth, onboarding: onboarding)
        vm.birthLocation = ""

        await vm.saveData()

        let data = onboarding.updatedData.first!.data
        XCTAssertFalse(data["birthLocation"] is String, "Empty birthLocation should use FieldValue.delete()")
        XCTAssertNotNil(data["birthLocation"], "FieldValue.delete() sentinel must be present")
    }

    func test_saveData_includesBirthDateWhenSet() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        let vm = makeViewModel(auth: auth, onboarding: onboarding)
        let refDate = Date(timeIntervalSince1970: 946684800)
        vm.birthDate = refDate

        await vm.saveData()

        let data = onboarding.updatedData.first!.data
        let ts = data["birthDate"] as? Timestamp
        XCTAssertNotNil(ts, "Non-nil birthDate should be written as Timestamp")
        XCTAssertEqual(ts!.dateValue().timeIntervalSince1970, refDate.timeIntervalSince1970, accuracy: 1)
    }

    func test_saveData_deleteBirthDateWhenNil() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        let vm = makeViewModel(auth: auth, onboarding: onboarding)
        vm.birthDate = nil

        await vm.saveData()

        let data = onboarding.updatedData.first!.data
        XCTAssertFalse(data["birthDate"] is Timestamp, "Nil birthDate should use FieldValue.delete()")
        XCTAssertNotNil(data["birthDate"], "FieldValue.delete() sentinel must be present")
    }

    func test_saveData_includesBirthTimeWhenSet() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        let vm = makeViewModel(auth: auth, onboarding: onboarding)
        let refTime = Date(timeIntervalSince1970: 946684800)
        vm.birthTime = refTime

        await vm.saveData()

        let data = onboarding.updatedData.first!.data
        let ts = data["birthTime"] as? Timestamp
        XCTAssertNotNil(ts, "Non-nil birthTime should be written as Timestamp")
        XCTAssertEqual(ts!.dateValue().timeIntervalSince1970, refTime.timeIntervalSince1970, accuracy: 1)
    }

    func test_saveData_deleteBirthTimeWhenNil() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        let vm = makeViewModel(auth: auth, onboarding: onboarding)
        vm.birthTime = nil

        await vm.saveData()

        let data = onboarding.updatedData.first!.data
        XCTAssertFalse(data["birthTime"] is Timestamp, "Nil birthTime should use FieldValue.delete()")
        XCTAssertNotNil(data["birthTime"], "FieldValue.delete() sentinel must be present")
    }

    func test_saveData_includesPersonalAnchorsAsStringArray() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        let vm = makeViewModel(auth: auth, onboarding: onboarding)
        vm.personalAnchors = [.direction, .love]

        await vm.saveData()

        let data = onboarding.updatedData.first!.data
        let anchors = data["personalAnchors"] as? [String]
        XCTAssertNotNil(anchors)
        XCTAssertEqual(anchors!.count, 2)
        XCTAssertTrue(anchors!.contains("Direction"))
        XCTAssertTrue(anchors!.contains("Love"))
    }

    func test_saveData_clearsHasUnsavedChanges_onSuccess() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        let vm = makeViewModel(auth: auth, onboarding: onboarding)
        vm.hasUnsavedChanges = true

        await vm.saveData()

        XCTAssertFalse(vm.hasUnsavedChanges)
    }

    func test_saveData_clearsSaveError_onSuccess() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        let vm = makeViewModel(auth: auth, onboarding: onboarding)
        vm.saveError = "Previous error"

        await vm.saveData()

        XCTAssertNil(vm.saveError)
    }

    func test_saveData_setsSaveError_onFailure() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        onboarding.updateResult = .failure(MockError.forced)
        let vm = makeViewModel(auth: auth, onboarding: onboarding)

        await vm.saveData()

        XCTAssertNotNil(vm.saveError)
        XCTAssertEqual(vm.saveError, "Could not save changes. Please try again.")
    }

    func test_saveData_preservesHasUnsavedChanges_onFailure() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        onboarding.updateResult = .failure(MockError.forced)
        let vm = makeViewModel(auth: auth, onboarding: onboarding)
        vm.hasUnsavedChanges = true

        await vm.saveData()

        XCTAssertTrue(vm.hasUnsavedChanges, "Unsaved flag must survive a failed save")
    }

    func test_saveData_retryAfterFailure_succeeds() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        onboarding.updateResult = .failure(MockError.forced)
        let vm = makeViewModel(auth: auth, onboarding: onboarding)
        vm.hasUnsavedChanges = true  // Simulate pending changes before first save attempt

        // First attempt fails
        await vm.saveData()
        XCTAssertNotNil(vm.saveError)
        XCTAssertTrue(vm.hasUnsavedChanges)

        // Retry succeeds
        onboarding.updateResult = .success(())
        await vm.saveData()

        XCTAssertNil(vm.saveError)
        XCTAssertFalse(vm.hasUnsavedChanges)
    }

    func test_saveData_isSavingFalseAfterCompletion() async {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let onboarding = MockOnboardingService()
        let vm = makeViewModel(auth: auth, onboarding: onboarding)

        await vm.saveData()

        XCTAssertFalse(vm.isSaving, "isSaving must be reset after save completes")
    }
}

// MARK: - Notification Tests

@MainActor
final class YouViewModel_NotificationTests: XCTestCase {

    func test_toggleOn_notDetermined_requestsPermission() async {
        let notif = MockNotificationService()
        notif.authorizationStatus = .notDetermined
        let vm = makeViewModel(notifications: notif)

        await vm.handleNotificationToggleOn()

        XCTAssertEqual(notif.requestAuthorizationCallCount, 1)
    }

    func test_toggleOn_notDetermined_granted_schedulesNotification() async {
        let notif = MockNotificationService()
        notif.authorizationStatus = .notDetermined
        notif.requestResult = .success(true)
        let vm = makeViewModel(notifications: notif)

        await vm.handleNotificationToggleOn()

        XCTAssertEqual(notif.scheduleCalls.count, 1)
    }

    func test_toggleOn_notDetermined_denied_setsEnabledFalse() async {
        let notif = MockNotificationService()
        notif.authorizationStatus = .notDetermined
        notif.requestResult = .success(false)
        let vm = makeViewModel(notifications: notif)
        vm.notificationsEnabled = true

        await vm.handleNotificationToggleOn()

        XCTAssertFalse(vm.notificationsEnabled)
        XCTAssertEqual(notif.scheduleCalls.count, 0, "Should not schedule if permission denied")
    }

    func test_toggleOn_authorized_schedulesImmediately() async {
        let notif = MockNotificationService()
        notif.authorizationStatus = .authorized
        let vm = makeViewModel(notifications: notif)

        await vm.handleNotificationToggleOn()

        XCTAssertEqual(notif.scheduleCalls.count, 1)
        XCTAssertEqual(notif.requestAuthorizationCallCount, 0, "Should not re-request if already authorized")
    }

    func test_toggleOn_denied_showsDeniedAlert() async {
        let notif = MockNotificationService()
        notif.authorizationStatus = .denied
        let vm = makeViewModel(notifications: notif)

        await vm.handleNotificationToggleOn()

        XCTAssertTrue(vm.showNotificationDeniedAlert)
    }

    func test_toggleOn_denied_setsEnabledFalse() async {
        let notif = MockNotificationService()
        notif.authorizationStatus = .denied
        let vm = makeViewModel(notifications: notif)
        vm.notificationsEnabled = true

        await vm.handleNotificationToggleOn()

        XCTAssertFalse(vm.notificationsEnabled)
    }

    func test_cancelNotifications_callsCancelAll() {
        let notif = MockNotificationService()
        let vm = makeViewModel(notifications: notif)

        vm.cancelNotifications()

        XCTAssertEqual(notif.cancelCallCount, 1)
    }
}

// MARK: - Logout Tests

@MainActor
final class YouViewModel_LogoutTests: XCTestCase {

    func test_performLogout_callsSignOut() {
        let auth = MockAuthService()
        auth.currentUserId = "user-1"
        let vm = makeViewModel(auth: auth)

        vm.performLogout()

        XCTAssertEqual(auth.signOutCallCount, 1)
    }

    func test_performLogout_success_noError() {
        let auth = MockAuthService()
        auth.signOutResult = .success(())
        let vm = makeViewModel(auth: auth)

        vm.performLogout()

        XCTAssertNil(vm.logoutError)
    }

    func test_performLogout_failure_setsLogoutError() {
        let auth = MockAuthService()
        auth.signOutResult = .failure(MockError.forced)
        let vm = makeViewModel(auth: auth)

        vm.performLogout()

        XCTAssertNotNil(vm.logoutError)
        XCTAssertEqual(vm.logoutError, "Something went wrong. Please try again.")
    }
}

// MARK: - Change Tracking Tests

@MainActor
final class YouViewModel_ChangeTrackingTests: XCTestCase {

    func test_fieldChanged_setsHasUnsavedChanges() {
        let vm = makeViewModel()
        vm.hasUnsavedChanges = false

        vm.fieldChanged()

        XCTAssertTrue(vm.hasUnsavedChanges)
    }

    func test_fieldChanged_duringLoad_doesNotSetUnsavedChanges() {
        let vm = makeViewModel()
        vm.isPerformingLoad = true
        vm.hasUnsavedChanges = false

        vm.fieldChanged()

        XCTAssertFalse(vm.hasUnsavedChanges, "Changes during load should not mark as unsaved")
    }

    func test_birthDateChanged_setsBirthDateAndFlag() {
        let vm = makeViewModel()
        let date = Date(timeIntervalSince1970: 946684800)

        vm.birthDateChanged(date)

        XCTAssertEqual(vm.birthDate!.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 1)
        XCTAssertTrue(vm.hasSelectedDate)
        XCTAssertTrue(vm.hasUnsavedChanges)
    }

    func test_clearBirthTime_clearsBirthTimeAndFlag() {
        let vm = makeViewModel()
        vm.birthTime = Date()
        vm.hasSelectedTime = true

        vm.clearBirthTime()

        XCTAssertNil(vm.birthTime)
        XCTAssertFalse(vm.hasSelectedTime)
        XCTAssertTrue(vm.hasUnsavedChanges)
    }

    func test_toggleAnchor_insertsNewAnchor() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.personalAnchors.contains(.direction))

        vm.toggleAnchor(.direction)

        XCTAssertTrue(vm.personalAnchors.contains(.direction))
        XCTAssertTrue(vm.hasUnsavedChanges)
    }

    func test_toggleAnchor_removesExistingAnchor() {
        let vm = makeViewModel()
        vm.personalAnchors = [.direction]

        vm.toggleAnchor(.direction)

        XCTAssertFalse(vm.personalAnchors.contains(.direction))
        XCTAssertTrue(vm.hasUnsavedChanges)
    }
}
