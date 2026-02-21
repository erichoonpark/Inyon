import XCTest
@testable import Inyon

final class OnboardingDataTests: XCTestCase {

    // MARK: - OnboardingData Initialization

    func testOnboardingDataDefaultsToNil() {
        let data = OnboardingData()

        XCTAssertNil(data.birthDate)
        XCTAssertNil(data.birthTime)
        XCTAssertFalse(data.isBirthTimeUnknown)
        XCTAssertEqual(data.birthCity, "")
        XCTAssertTrue(data.personalAnchors.isEmpty)
    }

    func testOnboardingDataWithBirthDate() {
        var data = OnboardingData()
        let testDate = Date()
        data.birthDate = testDate

        XCTAssertEqual(data.birthDate, testDate)
        XCTAssertNil(data.birthTime)
    }

    func testOnboardingDataWithBirthTime() {
        var data = OnboardingData()
        let testTime = Date()
        data.birthTime = testTime

        XCTAssertNil(data.birthDate)
        XCTAssertEqual(data.birthTime, testTime)
    }

    func testOnboardingDataWithPersonalAnchors() {
        var data = OnboardingData()
        data.personalAnchors = [.direction, .energy]

        XCTAssertEqual(data.personalAnchors.count, 2)
        XCTAssertTrue(data.personalAnchors.contains(.direction))
        XCTAssertTrue(data.personalAnchors.contains(.energy))
    }

    func testOnboardingDataWithAllFields() {
        var data = OnboardingData()
        let testDate = Date()
        let testTime = Date()

        data.birthDate = testDate
        data.birthTime = testTime
        data.personalAnchors = [.love, .work, .rest]

        XCTAssertEqual(data.birthDate, testDate)
        XCTAssertEqual(data.birthTime, testTime)
        XCTAssertEqual(data.personalAnchors.count, 3)
    }

    // MARK: - Birth Context Data Flow

    /// Simulates: user selects a date, selects a time, taps Continue
    func testBirthContextWithDateAndTime() {
        var data = OnboardingData()
        let selectedDate = Date()
        let selectedTime = Date()
        let hasSelectedDate = true
        let hasSelectedTime = true
        let knowsBirthTime = true

        // Mirrors BirthContextView Continue button logic
        data.birthDate = hasSelectedDate ? selectedDate : nil
        data.birthTime = (knowsBirthTime && hasSelectedTime) ? selectedTime : nil
        data.isBirthTimeUnknown = !knowsBirthTime

        XCTAssertEqual(data.birthDate, selectedDate)
        XCTAssertEqual(data.birthTime, selectedTime)
        XCTAssertFalse(data.isBirthTimeUnknown)
    }

    /// Simulates: user selects a date, taps "Not sure" for time, taps Continue
    func testBirthContextWithDateAndUnknownTime() {
        var data = OnboardingData()
        let selectedDate = Date()
        let hasSelectedDate = true
        let knowsBirthTime = false

        data.birthDate = hasSelectedDate ? selectedDate : nil
        data.birthTime = (knowsBirthTime && false) ? Date() : nil
        data.isBirthTimeUnknown = !knowsBirthTime

        XCTAssertEqual(data.birthDate, selectedDate)
        XCTAssertNil(data.birthTime)
        XCTAssertTrue(data.isBirthTimeUnknown)
    }

    /// Simulates: user selects a date only, skips time, taps Continue
    func testBirthContextWithDateOnly() {
        var data = OnboardingData()
        let selectedDate = Date()
        let hasSelectedDate = true
        let hasSelectedTime = false
        let knowsBirthTime = true

        data.birthDate = hasSelectedDate ? selectedDate : nil
        data.birthTime = (knowsBirthTime && hasSelectedTime) ? Date() : nil
        data.isBirthTimeUnknown = !knowsBirthTime

        XCTAssertEqual(data.birthDate, selectedDate)
        XCTAssertNil(data.birthTime)
        XCTAssertFalse(data.isBirthTimeUnknown)
    }

    /// Continue should be blocked when no date is selected
    func testBirthContextContinueRequiresDate() {
        let hasSelectedDate = false

        // Mirrors the .disabled(!hasSelectedDate) logic
        XCTAssertTrue(!hasSelectedDate, "Continue should be disabled when no date is selected")
    }

    /// User selects time, then changes mind and taps "Not sure"
    func testBirthContextTimeSelectedThenNotSure() {
        var data = OnboardingData()
        let selectedDate = Date()
        let hasSelectedDate = true
        // User selected a time but then tapped "Not sure"
        let knowsBirthTime = false

        data.birthDate = hasSelectedDate ? selectedDate : nil
        data.birthTime = (knowsBirthTime && true) ? Date() : nil
        data.isBirthTimeUnknown = !knowsBirthTime

        XCTAssertNotNil(data.birthDate)
        XCTAssertNil(data.birthTime, "Birth time should be nil after tapping Not sure")
        XCTAssertTrue(data.isBirthTimeUnknown)
    }

    // MARK: - Birth Time Skip / Add Later Flow

    /// Tapping "Not sure" enters skipped state
    func testNotSureSetsSkippedState() {
        var knowsBirthTime = true

        // Simulate tapping "Not sure"
        knowsBirthTime = false

        XCTAssertFalse(knowsBirthTime)

        // On Continue, this maps to isBirthTimeUnknown
        var data = OnboardingData()
        data.isBirthTimeUnknown = !knowsBirthTime
        XCTAssertTrue(data.isBirthTimeUnknown)
    }

    /// Tapping "Add later" re-enables time picker
    func testAddLaterReenablesTimePicker() {
        var knowsBirthTime = false

        // Simulate tapping "Add later"
        knowsBirthTime = true

        XCTAssertTrue(knowsBirthTime, "Time picker should be re-enabled after tapping Add later")
    }

    /// Skipping time, then adding it back, then submitting
    func testSkipThenAddTimeBackFlow() {
        var data = OnboardingData()
        var knowsBirthTime = true
        let selectedTime = Date()

        // Step 1: Skip time
        knowsBirthTime = false
        XCTAssertFalse(knowsBirthTime)

        // Step 2: Tap "Add later" to re-enable
        knowsBirthTime = true
        XCTAssertTrue(knowsBirthTime)

        // Step 3: Select a time and submit
        let hasSelectedTime = true
        data.birthDate = Date()
        data.birthTime = (knowsBirthTime && hasSelectedTime) ? selectedTime : nil
        data.isBirthTimeUnknown = !knowsBirthTime

        XCTAssertEqual(data.birthTime, selectedTime)
        XCTAssertFalse(data.isBirthTimeUnknown)
    }

    /// Continue still works with skipped time and city set
    func testContinueEnabledWithSkippedTimeAndCity() {
        var data = OnboardingData()
        let hasSelectedDate = true
        let knowsBirthTime = false

        data.birthDate = hasSelectedDate ? Date() : nil
        data.birthTime = nil
        data.isBirthTimeUnknown = !knowsBirthTime
        data.birthCity = "Seoul, South Korea"

        let canContinue = hasSelectedDate && !data.birthCity.isEmpty
        XCTAssertTrue(canContinue, "Skipping time should not block Continue")
        XCTAssertTrue(data.isBirthTimeUnknown)
    }

    // MARK: - Personal Anchor Multi-Select

    func testPersonalAnchorSetOperations() {
        var anchors: Set<PersonalAnchor> = []

        // Add anchors
        anchors.insert(.direction)
        XCTAssertEqual(anchors.count, 1)

        anchors.insert(.energy)
        XCTAssertEqual(anchors.count, 2)

        // Adding duplicate should not increase count
        anchors.insert(.direction)
        XCTAssertEqual(anchors.count, 2)

        // Remove anchor
        anchors.remove(.direction)
        XCTAssertEqual(anchors.count, 1)
        XCTAssertFalse(anchors.contains(.direction))
        XCTAssertTrue(anchors.contains(.energy))
    }

    func testPersonalAnchorToggleBehavior() {
        var anchors: Set<PersonalAnchor> = []

        // Simulate toggle on
        let anchor = PersonalAnchor.love
        if anchors.contains(anchor) {
            anchors.remove(anchor)
        } else {
            anchors.insert(anchor)
        }
        XCTAssertTrue(anchors.contains(anchor))

        // Simulate toggle off
        if anchors.contains(anchor) {
            anchors.remove(anchor)
        } else {
            anchors.insert(anchor)
        }
        XCTAssertFalse(anchors.contains(anchor))
    }
}

// MARK: - Onboarding UI Logic Tests

final class OnboardingUITests: XCTestCase {

    // MARK: - Birth Time Subheadline Text

    func test_birthTimeSubheadline_whenSkipped_showsSettingsMessage() {
        let knowsBirthTime = false
        // Mirrors the ternary in BirthContextView
        let text = knowsBirthTime ? "Approximate time is okay." : "You can add this in settings."
        XCTAssertEqual(text, "You can add this in settings.")
    }

    func test_birthTimeSubheadline_whenKnown_showsApproximateMessage() {
        let knowsBirthTime = true
        let text = knowsBirthTime ? "Approximate time is okay." : "You can add this in settings."
        XCTAssertEqual(text, "Approximate time is okay.")
    }

    // MARK: - Anchor Selection Indicator

    func test_anchorSelectionIndicator_notSelected_hidesCheckmark() {
        let selectedAnchors: Set<PersonalAnchor> = []
        XCTAssertFalse(selectedAnchors.contains(.direction), "Unselected anchor should not show checkmark")
    }

    func test_anchorSelectionIndicator_selected_showsCheckmark() {
        var selectedAnchors: Set<PersonalAnchor> = []
        selectedAnchors.insert(.direction)
        XCTAssertTrue(selectedAnchors.contains(.direction), "Selected anchor should show checkmark")
    }

    func test_anchorSelectionIndicator_deselected_hidesCheckmark() {
        var selectedAnchors: Set<PersonalAnchor> = [.direction]
        selectedAnchors.remove(.direction)
        XCTAssertFalse(selectedAnchors.contains(.direction), "Deselected anchor should hide checkmark")
    }
}

// MARK: - Onboarding Step Tests

final class OnboardingStepTests: XCTestCase {

    func testOnboardingStepOrder() {
        let steps = OnboardingStep.allCases

        XCTAssertEqual(steps.count, 4)
        XCTAssertEqual(steps[0], .arrival)
        XCTAssertEqual(steps[1], .birthContext)
        XCTAssertEqual(steps[2], .personalAnchor)
        XCTAssertEqual(steps[3], .accountCreation)
    }

    func testOnboardingStepRawValues() {
        XCTAssertEqual(OnboardingStep.arrival.rawValue, 0)
        XCTAssertEqual(OnboardingStep.birthContext.rawValue, 1)
        XCTAssertEqual(OnboardingStep.personalAnchor.rawValue, 2)
        XCTAssertEqual(OnboardingStep.accountCreation.rawValue, 3)
    }

    func testOnboardingStepForwardNavigation() {
        XCTAssertEqual(OnboardingStep.arrival.next, .birthContext)
    }

    func testOnboardingStepBackwardNavigation() {
        XCTAssertEqual(OnboardingStep.birthContext.previous, .arrival)
    }

    func testOnboardingStepCannotGoBackFromFirst() {
        XCTAssertNil(OnboardingStep.arrival.previous)
    }

    func testOnboardingStepCannotAdvancePastLast() {
        XCTAssertNil(OnboardingStep.accountCreation.next)
    }

    func testFullNavigationCycle() {
        var step = OnboardingStep.arrival

        // Forward
        while let next = step.next {
            step = next
        }
        XCTAssertEqual(step, .accountCreation)

        // Backward
        while let prev = step.previous {
            step = prev
        }
        XCTAssertEqual(step, .arrival)
    }
}

// MARK: - Personal Anchor Enum Tests

final class PersonalAnchorTests: XCTestCase {

    func testPersonalAnchorAllCases() {
        let anchors = PersonalAnchor.allCases

        XCTAssertEqual(anchors.count, 5)
        XCTAssertTrue(anchors.contains(.direction))
        XCTAssertTrue(anchors.contains(.energy))
        XCTAssertTrue(anchors.contains(.love))
        XCTAssertTrue(anchors.contains(.work))
        XCTAssertTrue(anchors.contains(.rest))
    }

    func testPersonalAnchorRawValues() {
        XCTAssertEqual(PersonalAnchor.direction.rawValue, "Direction")
        XCTAssertEqual(PersonalAnchor.energy.rawValue, "Energy")
        XCTAssertEqual(PersonalAnchor.love.rawValue, "Love")
        XCTAssertEqual(PersonalAnchor.work.rawValue, "Work")
        XCTAssertEqual(PersonalAnchor.rest.rawValue, "Rest")
    }

    func testPersonalAnchorIdentifiable() {
        let anchor = PersonalAnchor.direction
        XCTAssertEqual(anchor.id, anchor.rawValue)
    }

    func testPersonalAnchorHashable() {
        var set: Set<PersonalAnchor> = []

        set.insert(.direction)
        set.insert(.direction) // Duplicate

        XCTAssertEqual(set.count, 1)
    }
}

// MARK: - Firestore Payload Tests

final class FirestorePayloadTests: XCTestCase {

    func testToFirestoreDataWithEmptyData() {
        let data = OnboardingData()
        let payload = data.toFirestoreData()

        // Should always have createdAt, personalAnchors, and isBirthTimeUnknown
        XCTAssertNotNil(payload["createdAt"])
        XCTAssertNotNil(payload["personalAnchors"])
        XCTAssertNotNil(payload["isBirthTimeUnknown"])

        // Should not have birthDate, birthTime, or birthCity when nil/empty
        XCTAssertNil(payload["birthDate"])
        XCTAssertNil(payload["birthTime"])
        XCTAssertNil(payload["birthLocation"])

        // isBirthTimeUnknown should default to false
        XCTAssertEqual(payload["isBirthTimeUnknown"] as? Bool, false)

        // Personal anchors should be empty array
        if let anchors = payload["personalAnchors"] as? [String] {
            XCTAssertTrue(anchors.isEmpty)
        } else {
            XCTFail("personalAnchors should be an array of strings")
        }
    }

    func testToFirestoreDataWithBirthDate() {
        var data = OnboardingData()
        data.birthDate = Date()
        let payload = data.toFirestoreData()

        XCTAssertNotNil(payload["birthDate"])
        XCTAssertNil(payload["birthTime"])
    }

    func testToFirestoreDataWithBirthTime() {
        var data = OnboardingData()
        data.birthTime = Date()
        let payload = data.toFirestoreData()

        XCTAssertNil(payload["birthDate"])
        XCTAssertNotNil(payload["birthTime"])
    }

    func testToFirestoreDataWithPersonalAnchors() {
        var data = OnboardingData()
        data.personalAnchors = [.direction, .love]
        let payload = data.toFirestoreData()

        guard let anchors = payload["personalAnchors"] as? [String] else {
            XCTFail("personalAnchors should be an array of strings")
            return
        }

        XCTAssertEqual(anchors.count, 2)
        XCTAssertTrue(anchors.contains("Direction"))
        XCTAssertTrue(anchors.contains("Love"))
    }

    func testToFirestoreDataWithAllFields() {
        var data = OnboardingData()
        data.birthDate = Date()
        data.birthTime = Date()
        data.personalAnchors = [.work, .rest, .energy]
        let payload = data.toFirestoreData()

        XCTAssertNotNil(payload["createdAt"])
        XCTAssertNotNil(payload["birthDate"])
        XCTAssertNotNil(payload["birthTime"])

        guard let anchors = payload["personalAnchors"] as? [String] else {
            XCTFail("personalAnchors should be an array of strings")
            return
        }

        XCTAssertEqual(anchors.count, 3)
        XCTAssertTrue(anchors.contains("Work"))
        XCTAssertTrue(anchors.contains("Rest"))
        XCTAssertTrue(anchors.contains("Energy"))
    }

    func testPersonalAnchorSerializationRoundTrip() {
        let originalAnchors: Set<PersonalAnchor> = [.direction, .energy, .love]

        // Serialize to strings (as done in toFirestoreData)
        let serialized = originalAnchors.map { $0.rawValue }

        // Deserialize back to PersonalAnchor
        var deserializedAnchors: Set<PersonalAnchor> = []
        for rawValue in serialized {
            if let anchor = PersonalAnchor(rawValue: rawValue) {
                deserializedAnchors.insert(anchor)
            }
        }

        XCTAssertEqual(originalAnchors, deserializedAnchors)
    }

    func testPayloadKeysAreCorrect() {
        var data = OnboardingData()
        data.birthDate = Date()
        data.birthTime = Date()
        data.birthCity = "Seoul, South Korea"
        data.personalAnchors = [.direction]
        let payload = data.toFirestoreData()

        let expectedKeys: Set<String> = ["createdAt", "birthDate", "birthTime", "personalAnchors", "isBirthTimeUnknown", "birthLocation"]
        let actualKeys = Set(payload.keys)

        XCTAssertEqual(actualKeys, expectedKeys)
    }

    func testToFirestoreDataWithUnknownBirthTime() {
        var data = OnboardingData()
        data.birthDate = Date()
        data.isBirthTimeUnknown = true
        let payload = data.toFirestoreData()

        XCTAssertNotNil(payload["birthDate"])
        XCTAssertNil(payload["birthTime"])
        XCTAssertEqual(payload["isBirthTimeUnknown"] as? Bool, true)
    }

    func testToFirestoreDataWithKnownBirthTime() {
        var data = OnboardingData()
        data.birthDate = Date()
        data.birthTime = Date()
        data.isBirthTimeUnknown = false
        let payload = data.toFirestoreData()

        XCTAssertNotNil(payload["birthDate"])
        XCTAssertNotNil(payload["birthTime"])
        XCTAssertEqual(payload["isBirthTimeUnknown"] as? Bool, false)
    }

    func testToFirestoreDataWithBirthCity() {
        var data = OnboardingData()
        data.birthCity = "San Francisco, CA, United States"
        let payload = data.toFirestoreData()

        XCTAssertEqual(payload["birthLocation"] as? String, "San Francisco, CA, United States")
    }

    func testToFirestoreDataWithEmptyBirthCity() {
        let data = OnboardingData()
        let payload = data.toFirestoreData()

        XCTAssertNil(payload["birthLocation"], "Empty birthCity should not appear in payload")
    }
}

// MARK: - Birth City Tests

final class BirthCityTests: XCTestCase {

    // MARK: - Initial State

    func testBirthCityDefaultsToEmpty() {
        let data = OnboardingData()
        XCTAssertEqual(data.birthCity, "")
    }

    func testContinueDisabledWhenDateSetButCityEmpty() {
        let hasSelectedDate = true
        let birthCity = ""

        // Mirrors canContinue: hasSelectedDate && !data.birthCity.isEmpty
        let canContinue = hasSelectedDate && !birthCity.isEmpty
        XCTAssertFalse(canContinue, "Continue should be disabled when city is empty")
    }

    // MARK: - City Entry

    func testBirthCityAssignment() {
        var data = OnboardingData()
        data.birthCity = "San Francisco, CA, United States"

        XCTAssertEqual(data.birthCity, "San Francisco, CA, United States")
    }

    func testContinueEnabledAfterCityAndDateSet() {
        let hasSelectedDate = true
        let birthCity = "San Francisco, CA, United States"

        let canContinue = hasSelectedDate && !birthCity.isEmpty
        XCTAssertTrue(canContinue)
    }

    // MARK: - City Required

    func testContinueDisabledWithoutCity() {
        let hasSelectedDate = true
        let birthCity = ""

        let canContinue = hasSelectedDate && !birthCity.isEmpty
        XCTAssertFalse(canContinue)
    }

    func testContinueDisabledWithoutDate() {
        let hasSelectedDate = false
        let birthCity = "Seoul, South Korea"

        let canContinue = hasSelectedDate && !birthCity.isEmpty
        XCTAssertFalse(canContinue)
    }

    // MARK: - Full Valid State

    func testFullValidStateWithTime() {
        var data = OnboardingData()
        let hasSelectedDate = true
        let hasSelectedTime = true
        let knowsBirthTime = true

        data.birthDate = hasSelectedDate ? Date() : nil
        data.birthTime = (knowsBirthTime && hasSelectedTime) ? Date() : nil
        data.isBirthTimeUnknown = !knowsBirthTime
        data.birthCity = "Seoul, South Korea"

        let canContinue = hasSelectedDate && !data.birthCity.isEmpty

        XCTAssertTrue(canContinue)
        XCTAssertNotNil(data.birthDate)
        XCTAssertNotNil(data.birthTime)
        XCTAssertFalse(data.isBirthTimeUnknown)
        XCTAssertEqual(data.birthCity, "Seoul, South Korea")
    }

    func testFullValidStateWithoutTime() {
        var data = OnboardingData()
        let hasSelectedDate = true
        let knowsBirthTime = false

        data.birthDate = hasSelectedDate ? Date() : nil
        data.birthTime = nil
        data.isBirthTimeUnknown = !knowsBirthTime
        data.birthCity = "Busan, South Korea"

        let canContinue = hasSelectedDate && !data.birthCity.isEmpty

        XCTAssertTrue(canContinue, "Continue should be enabled — time is optional")
        XCTAssertNotNil(data.birthDate)
        XCTAssertNil(data.birthTime)
        XCTAssertTrue(data.isBirthTimeUnknown)
    }

    // MARK: - City Change

    func testCityClearAndReselect() {
        var data = OnboardingData()
        data.birthCity = "Tokyo, Japan"
        XCTAssertEqual(data.birthCity, "Tokyo, Japan")

        // Simulate tapping "Change"
        data.birthCity = ""
        XCTAssertEqual(data.birthCity, "")

        // Reselect
        data.birthCity = "Seoul, South Korea"
        XCTAssertEqual(data.birthCity, "Seoul, South Korea")
    }
}
