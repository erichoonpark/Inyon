import XCTest

final class InyonUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Launch

    func testAppLaunches() throws {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }

    // MARK: - Onboarding Smoke Test

    func testOnboardingShowsGetStarted() throws {
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 10), "Get Started button should appear on first launch")
    }

    func testOnboardingGetStartedAdvancesToBirthContext() throws {
        let getStarted = app.buttons["Get Started"]
        guard getStarted.waitForExistence(timeout: 10) else {
            XCTFail("Get Started button not found")
            return
        }
        getStarted.tap()

        let birthDateLabel = app.staticTexts["BIRTH DATE"]
        XCTAssertTrue(birthDateLabel.waitForExistence(timeout: 5), "Birth context screen should appear after tapping Get Started")
    }
}
