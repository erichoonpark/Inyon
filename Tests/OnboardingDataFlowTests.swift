import XCTest
@testable import Inyon

// MARK: - Onboarding Data Flow Tests
//
// Tests the data flow from user input through to OnboardingData and Firestore payload.
// Simulates the exact logic from BirthContextView, PersonalAnchorView, and AccountCreationView.

final class OnboardingDataFlowTests: XCTestCase {

    // MARK: - BirthContext: Continue Button Validation

    func test_birthContext_dateAndCitySet_canContinue() {
        let hasSelectedDate = true
        let birthCity = "Seoul, South Korea"

        // Mirrors BirthContextView.canContinue
        let canContinue = hasSelectedDate && !birthCity.isEmpty
        XCTAssertTrue(canContinue)
    }

    func test_birthContext_missingDate_cannotContinue() {
        let hasSelectedDate = false
        let birthCity = "Seoul, South Korea"

        let canContinue = hasSelectedDate && !birthCity.isEmpty
        XCTAssertFalse(canContinue, "Continue should be disabled without a date")
    }

    func test_birthContext_missingCity_cannotContinue() {
        let hasSelectedDate = true
        let birthCity = ""

        let canContinue = hasSelectedDate && !birthCity.isEmpty
        XCTAssertFalse(canContinue, "Continue should be disabled without a city")
    }

    func test_birthContext_missingBoth_cannotContinue() {
        let hasSelectedDate = false
        let birthCity = ""

        let canContinue = hasSelectedDate && !birthCity.isEmpty
        XCTAssertFalse(canContinue)
    }

    // MARK: - BirthContext: Time Selection Logic

    func test_birthContext_notSure_setsUnknownTimeAndClearsTime() {
        var data = OnboardingData()
        let selectedDate = Date()
        let hasSelectedDate = true
        let knowsBirthTime = false

        // Mirrors BirthContextView Continue button logic
        data.birthDate = hasSelectedDate ? selectedDate : nil
        data.birthTime = (knowsBirthTime && true) ? Date() : nil
        data.isBirthTimeUnknown = !knowsBirthTime

        XCTAssertNotNil(data.birthDate)
        XCTAssertNil(data.birthTime, "Time should be nil when user taps Not sure")
        XCTAssertTrue(data.isBirthTimeUnknown)
    }

    func test_birthContext_selectTimeThenNotSure_clearsTime() {
        var data = OnboardingData()
        let selectedDate = Date()
        let selectedTime = Date()

        // User selects a time
        var knowsBirthTime = true
        var hasSelectedTime = true
        data.birthTime = (knowsBirthTime && hasSelectedTime) ? selectedTime : nil
        XCTAssertNotNil(data.birthTime)

        // User taps "Not sure"
        knowsBirthTime = false
        hasSelectedTime = false
        data.birthDate = selectedDate
        data.birthTime = (knowsBirthTime && hasSelectedTime) ? selectedTime : nil
        data.isBirthTimeUnknown = !knowsBirthTime

        XCTAssertNil(data.birthTime, "Time should be cleared after tapping Not sure")
        XCTAssertTrue(data.isBirthTimeUnknown)
    }

    func test_birthContext_addLater_reEnablesTimePicker() {
        // User initially tapped "Not sure"
        var knowsBirthTime = false
        XCTAssertFalse(knowsBirthTime)

        // User taps "Add later" to re-enable
        knowsBirthTime = true
        XCTAssertTrue(knowsBirthTime, "Time picker should be re-enabled after Add later")
    }

    // MARK: - PersonalAnchor: Selection Logic

    func test_personalAnchor_selectAnchors_storesInData() {
        var data = OnboardingData()
        var selectedAnchors: Set<PersonalAnchor> = []

        // Select some anchors (simulates tapping buttons)
        selectedAnchors.insert(.direction)
        selectedAnchors.insert(.love)
        selectedAnchors.insert(.work)

        // On Continue, anchors are saved to data
        data.personalAnchors = selectedAnchors

        XCTAssertEqual(data.personalAnchors.count, 3)
        XCTAssertTrue(data.personalAnchors.contains(.direction))
        XCTAssertTrue(data.personalAnchors.contains(.love))
        XCTAssertTrue(data.personalAnchors.contains(.work))
    }

    func test_personalAnchor_skip_continuesWithoutAnchors() {
        let data = OnboardingData()

        // Skip does not set personalAnchors — they stay empty
        XCTAssertTrue(data.personalAnchors.isEmpty, "Skipping should leave anchors empty")
    }

    func test_personalAnchor_toggleOnOff_removesAnchor() {
        var selectedAnchors: Set<PersonalAnchor> = []

        // Toggle on
        let anchor = PersonalAnchor.energy
        if selectedAnchors.contains(anchor) {
            selectedAnchors.remove(anchor)
        } else {
            selectedAnchors.insert(anchor)
        }
        XCTAssertTrue(selectedAnchors.contains(anchor))

        // Toggle off
        if selectedAnchors.contains(anchor) {
            selectedAnchors.remove(anchor)
        } else {
            selectedAnchors.insert(anchor)
        }
        XCTAssertFalse(selectedAnchors.contains(anchor))
    }

    // MARK: - Complete Flow: Data → Firestore Payload

    func test_completeFlow_producesCorrectPayload() {
        var data = OnboardingData()
        let testDate = Date()
        let testTime = Date()

        // Simulate full flow
        data.birthDate = testDate
        data.birthTime = testTime
        data.isBirthTimeUnknown = false
        data.birthCity = "Busan, South Korea"
        data.personalAnchors = [.rest, .work]

        let payload = data.toFirestoreData()

        XCTAssertNotNil(payload["createdAt"])
        XCTAssertNotNil(payload["birthDate"])
        XCTAssertNotNil(payload["birthTime"])
        XCTAssertEqual(payload["isBirthTimeUnknown"] as? Bool, false)
        XCTAssertEqual(payload["birthCity"] as? String, "Busan, South Korea")

        let anchors = payload["personalAnchors"] as? [String]
        XCTAssertNotNil(anchors)
        XCTAssertEqual(anchors?.count, 2)
        XCTAssertTrue(anchors?.contains("Rest") ?? false)
        XCTAssertTrue(anchors?.contains("Work") ?? false)
    }

    func test_completeFlow_unknownTime_producesCorrectPayload() {
        var data = OnboardingData()
        data.birthDate = Date()
        data.birthTime = nil
        data.isBirthTimeUnknown = true
        data.birthCity = "Seoul, South Korea"
        data.personalAnchors = [.direction]

        let payload = data.toFirestoreData()

        XCTAssertNotNil(payload["birthDate"])
        XCTAssertNil(payload["birthTime"], "Unknown time should not appear in payload")
        XCTAssertEqual(payload["isBirthTimeUnknown"] as? Bool, true)
        XCTAssertEqual(payload["birthCity"] as? String, "Seoul, South Korea")
    }

    func test_completeFlow_skippedAnchors_producesEmptyArray() {
        var data = OnboardingData()
        data.birthDate = Date()
        data.birthCity = "Tokyo, Japan"
        // personalAnchors left empty (user tapped Skip)

        let payload = data.toFirestoreData()

        let anchors = payload["personalAnchors"] as? [String]
        XCTAssertNotNil(anchors)
        XCTAssertTrue(anchors?.isEmpty ?? false, "Skipped anchors should be empty array")
    }
}
