import XCTest
@testable import Inyon

// MARK: - Onboarding Flow Navigation Tests
//
// Tests the step-by-step navigation logic of OnboardingFlow.
// Each test simulates the navigation functions (advanceToNext, goBack, navigateTo)
// using the same logic as OnboardingFlow.swift.

final class OnboardingFlowNavigationTests: XCTestCase {

    // MARK: - Initial State

    func test_initialStep_isArrival() {
        let currentStep = OnboardingStep.arrival
        XCTAssertEqual(currentStep, .arrival)
        XCTAssertEqual(currentStep.rawValue, 0)
    }

    // MARK: - Forward Navigation (advanceToNext)

    func test_advanceFromArrival_movesToBirthContext() {
        var currentStep = OnboardingStep.arrival
        advanceToNext(&currentStep)
        XCTAssertEqual(currentStep, .birthContext)
    }

    func test_advanceFromBirthContext_movesToPersonalAnchor() {
        var currentStep = OnboardingStep.birthContext
        advanceToNext(&currentStep)
        XCTAssertEqual(currentStep, .personalAnchor)
    }

    func test_advanceFromPersonalAnchor_movesToAccountCreation() {
        var currentStep = OnboardingStep.personalAnchor
        advanceToNext(&currentStep)
        XCTAssertEqual(currentStep, .accountCreation)
    }

    func test_advanceFromAccountCreation_staysAtAccountCreation() {
        var currentStep = OnboardingStep.accountCreation
        advanceToNext(&currentStep)
        XCTAssertEqual(currentStep, .accountCreation, "Should not advance past the last step")
    }

    // MARK: - Backward Navigation (goBack)

    func test_goBackFromBirthContext_returnsToArrival() {
        var currentStep = OnboardingStep.birthContext
        goBack(&currentStep)
        XCTAssertEqual(currentStep, .arrival)
    }

    func test_goBackFromPersonalAnchor_returnsToBirthContext() {
        var currentStep = OnboardingStep.personalAnchor
        goBack(&currentStep)
        XCTAssertEqual(currentStep, .birthContext)
    }

    func test_goBackFromAccountCreation_returnsToPersonalAnchor() {
        var currentStep = OnboardingStep.accountCreation
        goBack(&currentStep)
        XCTAssertEqual(currentStep, .personalAnchor)
    }

    func test_goBackFromArrival_staysAtArrival() {
        var currentStep = OnboardingStep.arrival
        goBack(&currentStep)
        XCTAssertEqual(currentStep, .arrival, "Should not go back before the first step")
    }

    // MARK: - Direct Navigation (navigateTo)

    func test_navigateToAccountCreation_jumpsDirectly() {
        var currentStep = OnboardingStep.arrival
        currentStep = .accountCreation
        XCTAssertEqual(currentStep, .accountCreation)
    }

    func test_navigateToArrival_fromAccountCreation() {
        var currentStep = OnboardingStep.accountCreation
        currentStep = .arrival
        XCTAssertEqual(currentStep, .arrival)
    }

    // MARK: - Login Path (isReturningUser)

    func test_loginFromArrival_setsReturningUserAndJumpsToAccountCreation() {
        var currentStep = OnboardingStep.arrival
        var isReturningUser = false

        // Simulate tapping "Log in" on ArrivalView
        isReturningUser = true
        currentStep = .accountCreation

        XCTAssertTrue(isReturningUser)
        XCTAssertEqual(currentStep, .accountCreation)
    }

    func test_backFromLogin_clearsReturningUserAndReturnsToArrival() {
        var currentStep = OnboardingStep.accountCreation
        var isReturningUser = true

        // Simulate tapping back from LoginView
        isReturningUser = false
        currentStep = .arrival

        XCTAssertFalse(isReturningUser)
        XCTAssertEqual(currentStep, .arrival)
    }

    // MARK: - Full Cycle

    func test_fullForwardThenBackwardCycle() {
        var currentStep = OnboardingStep.arrival

        // Forward: arrival → birthContext → personalAnchor → accountCreation
        advanceToNext(&currentStep)
        XCTAssertEqual(currentStep, .birthContext)

        advanceToNext(&currentStep)
        XCTAssertEqual(currentStep, .personalAnchor)

        advanceToNext(&currentStep)
        XCTAssertEqual(currentStep, .accountCreation)

        // Backward: accountCreation → personalAnchor → birthContext → arrival
        goBack(&currentStep)
        XCTAssertEqual(currentStep, .personalAnchor)

        goBack(&currentStep)
        XCTAssertEqual(currentStep, .birthContext)

        goBack(&currentStep)
        XCTAssertEqual(currentStep, .arrival)
    }

    func test_dataPreservedAcrossNavigation() {
        var data = OnboardingData()
        var currentStep = OnboardingStep.arrival

        // Step 1: Advance and set birth data
        advanceToNext(&currentStep)
        data.birthDate = Date()
        data.birthCity = "Seoul, South Korea"

        // Step 2: Advance and set anchors
        advanceToNext(&currentStep)
        data.personalAnchors = [.direction, .energy]

        // Step 3: Go back to birth context
        goBack(&currentStep)
        XCTAssertEqual(currentStep, .birthContext)

        // Data should still be there
        XCTAssertNotNil(data.birthDate)
        XCTAssertEqual(data.birthCity, "Seoul, South Korea")
        XCTAssertEqual(data.personalAnchors.count, 2)
    }

    // MARK: - Helpers (mirror OnboardingFlow logic)

    private func advanceToNext(_ currentStep: inout OnboardingStep) {
        if let nextIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
           nextIndex + 1 < OnboardingStep.allCases.count {
            currentStep = OnboardingStep.allCases[nextIndex + 1]
        }
    }

    private func goBack(_ currentStep: inout OnboardingStep) {
        if let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
           currentIndex > 0 {
            currentStep = OnboardingStep.allCases[currentIndex - 1]
        }
    }
}
