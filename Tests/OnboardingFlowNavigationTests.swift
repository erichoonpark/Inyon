import XCTest
@testable import Inyon

// MARK: - OnboardingStep Navigation Tests
//
// Tests the production OnboardingStep.next and .previous properties
// that drive navigation in OnboardingFlow.

final class OnboardingFlowNavigationTests: XCTestCase {

    // MARK: - Forward Navigation (.next)

    func test_arrival_next_isBirthContext() {
        XCTAssertEqual(OnboardingStep.arrival.next, .birthContext)
    }

    func test_birthContext_next_isPersonalAnchor() {
        XCTAssertEqual(OnboardingStep.birthContext.next, .personalAnchor)
    }

    func test_personalAnchor_next_isAccountCreation() {
        XCTAssertEqual(OnboardingStep.personalAnchor.next, .accountCreation)
    }

    func test_accountCreation_next_isNil() {
        XCTAssertNil(OnboardingStep.accountCreation.next, "Should not advance past last step")
    }

    // MARK: - Backward Navigation (.previous)

    func test_birthContext_previous_isArrival() {
        XCTAssertEqual(OnboardingStep.birthContext.previous, .arrival)
    }

    func test_personalAnchor_previous_isBirthContext() {
        XCTAssertEqual(OnboardingStep.personalAnchor.previous, .birthContext)
    }

    func test_accountCreation_previous_isPersonalAnchor() {
        XCTAssertEqual(OnboardingStep.accountCreation.previous, .personalAnchor)
    }

    func test_arrival_previous_isNil() {
        XCTAssertNil(OnboardingStep.arrival.previous, "Should not go back before first step")
    }

    // MARK: - Full Cycle

    func test_fullForwardCycle() {
        var step = OnboardingStep.arrival

        step = step.next!
        XCTAssertEqual(step, .birthContext)

        step = step.next!
        XCTAssertEqual(step, .personalAnchor)

        step = step.next!
        XCTAssertEqual(step, .accountCreation)

        XCTAssertNil(step.next)
    }

    func test_fullBackwardCycle() {
        var step = OnboardingStep.accountCreation

        step = step.previous!
        XCTAssertEqual(step, .personalAnchor)

        step = step.previous!
        XCTAssertEqual(step, .birthContext)

        step = step.previous!
        XCTAssertEqual(step, .arrival)

        XCTAssertNil(step.previous)
    }

    // MARK: - Login Path

    func test_loginPath_jumpsToAccountCreation() {
        // Login goes directly to accountCreation, bypassing intermediate steps
        let step = OnboardingStep.accountCreation
        XCTAssertEqual(step, .accountCreation)
        XCTAssertEqual(step.previous, .personalAnchor)
    }

    // MARK: - Step Ordering

    func test_stepCount() {
        XCTAssertEqual(OnboardingStep.allCases.count, 4)
    }

    func test_stepOrder() {
        let steps = OnboardingStep.allCases
        XCTAssertEqual(steps[0], .arrival)
        XCTAssertEqual(steps[1], .birthContext)
        XCTAssertEqual(steps[2], .personalAnchor)
        XCTAssertEqual(steps[3], .accountCreation)
    }

    func test_dataPreservedAcrossNavigation() {
        var data = OnboardingData()
        var step = OnboardingStep.arrival

        step = step.next!
        data.birthDate = Date()
        data.birthCity = "Seoul, South Korea"

        step = step.next!
        data.personalAnchors = [.direction, .energy]

        step = step.previous!
        XCTAssertEqual(step, .birthContext)

        XCTAssertNotNil(data.birthDate)
        XCTAssertEqual(data.birthCity, "Seoul, South Korea")
        XCTAssertEqual(data.personalAnchors.count, 2)
    }
}
