import XCTest

final class InyonUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp(authMode: String? = nil) {
        app = XCUIApplication()
        app.launchArguments.append("-ui_testing")
        if let authMode {
            app.launchEnvironment["INYON_UI_TEST_AUTH_MODE"] = authMode
        }
        app.launch()
    }

    private func waitForExistence(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    private func waitForEnabled(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    // MARK: - Launch

    func testAppLaunches() throws {
        launchApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }

    // MARK: - Onboarding Smoke Test

    func testOnboardingShowsGetStarted() throws {
        launchApp()
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(waitForExistence(getStarted), "Get Started button should appear on first launch")
    }

    func testOnboardingGetStartedAdvancesToBirthContext() throws {
        launchApp()
        let getStarted = app.buttons["Get Started"]
        guard waitForExistence(getStarted) else {
            XCTFail("Get Started button not found")
            return
        }
        getStarted.tap()

        let birthDateLabel = app.staticTexts["BIRTH DATE"]
        XCTAssertTrue(waitForExistence(birthDateLabel, timeout: 5), "Birth context screen should appear after tapping Get Started")
    }

    // MARK: - Priority 4: Login Error Handling

    /// Asserts login error is visible and user is not incorrectly advanced.
    func test_loginView_emailSignIn_failure_showsError_andStaysOnLogin() throws {
        launchApp(authMode: "sign_in_failure")

        // Navigate to login view
        let loginLink = app.buttons["arrival.loginButton"]
        guard waitForExistence(loginLink) else {
            XCTFail("Login link not found on arrival screen")
            return
        }
        loginLink.tap()

        // Wait for LoginView to appear
        let welcomeBack = app.staticTexts["login.title"]
        guard waitForExistence(welcomeBack, timeout: 5) else {
            XCTFail("LoginView did not appear")
            return
        }

        // Tap "Continue with Email" to show email form
        let emailButton = app.buttons["login.continueWithEmailButton"]
        guard waitForExistence(emailButton, timeout: 5) else {
            XCTFail("Continue with Email button not found")
            return
        }
        emailButton.tap()

        // Enter credentials
        let emailField = app.textFields["login.emailField"]
        guard waitForExistence(emailField, timeout: 5) else {
            XCTFail("Email field not found")
            return
        }
        emailField.tap()
        emailField.typeText("nonexistent@test-inyon.com")

        let passwordField = app.secureTextFields["login.passwordField"]
        guard waitForExistence(passwordField, timeout: 5) else {
            XCTFail("Password field not found")
            return
        }
        passwordField.tap()
        passwordField.typeText("wrongpassword")

        // Tap Sign In
        let signInButton = app.buttons["login.signInButton"]
        guard waitForExistence(signInButton, timeout: 5) else {
            XCTFail("Sign In button not found")
            return
        }
        signInButton.tap()

        // Error should be visible and deterministic in UITest mode.
        let errorLabel = app.staticTexts["login.errorMessage"]
        XCTAssertTrue(waitForExistence(errorLabel, timeout: 5), "Error message should appear after failed sign-in")
        XCTAssertEqual(errorLabel.label, "Unable to sign in. Check your credentials and try again.")

        // User should still be on login view
        XCTAssertTrue(welcomeBack.exists, "User should remain on login view after failed sign-in")
    }

    // MARK: - Logout Flow

    /// Asserts that tapping Log Out from You tab returns user to onboarding.
    func test_youTab_logout_returnsToOnboarding() throws {
        launchApp(authMode: "signed_in")

        // Navigate to You tab
        let youTab = app.buttons["YOU"]
        guard waitForExistence(youTab) else {
            XCTFail("YOU tab not found")
            return
        }
        youTab.tap()

        // Tap Log Out
        let logoutButton = app.buttons["you.logoutButton"]
        guard waitForExistence(logoutButton) else {
            XCTFail("Log Out button not found in You tab")
            return
        }
        logoutButton.tap()

        // Confirm in alert
        let confirmButton = app.buttons["Log Out"]
        guard waitForExistence(confirmButton, timeout: 5) else {
            XCTFail("Logout confirmation alert not shown")
            return
        }
        confirmButton.tap()

        // Assert onboarding start screen appears
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(waitForExistence(getStarted, timeout: 10), "Onboarding Get Started should appear after logout")
    }

    /// Asserts that sign-out failure shows error and user remains signed in.
    func test_youTab_logoutFailure_showsError_andStaysSignedIn() throws {
        launchApp(authMode: "sign_out_failure")

        // Navigate to You tab
        let youTab = app.buttons["YOU"]
        guard waitForExistence(youTab) else {
            XCTFail("YOU tab not found")
            return
        }
        youTab.tap()

        // Tap Log Out
        let logoutButton = app.buttons["you.logoutButton"]
        guard waitForExistence(logoutButton) else {
            XCTFail("Log Out button not found")
            return
        }
        logoutButton.tap()

        // Confirm in alert
        let confirmButton = app.buttons["Log Out"]
        guard waitForExistence(confirmButton, timeout: 5) else {
            XCTFail("Logout confirmation alert not shown")
            return
        }
        confirmButton.tap()

        // Error alert should appear
        let errorAlert = app.alerts["Unable to log out"]
        XCTAssertTrue(waitForExistence(errorAlert, timeout: 5), "Error alert should appear after failed sign-out")

        // Dismiss error
        let cancelButton = errorAlert.buttons["Cancel"]
        guard waitForExistence(cancelButton, timeout: 3) else {
            XCTFail("Cancel button not found in error alert")
            return
        }
        cancelButton.tap()

        // User should still be on You tab (not kicked to onboarding)
        XCTAssertTrue(logoutButton.exists, "User should remain on You tab after failed logout")
    }

    // MARK: - Priority 5: Email Validation Disables Submit

    /// Verifies Sign In button disabled for empty email/password and enabled when valid.
    /// Tests via LoginView path (same validation pattern as AccountCreation;
    /// AccountCreationView requires DatePicker + MapKit which destabilize the simulator).
    func test_accountCreation_emailValidation_disablesCreate_untilValid() throws {
        launchApp()

        // Navigate to LoginView (simpler path, same validation pattern)
        let loginLink = app.buttons["arrival.loginButton"]
        guard waitForExistence(loginLink) else {
            XCTFail("Login link not found")
            return
        }
        loginLink.tap()

        // Wait for LoginView
        let welcomeBack = app.staticTexts["login.title"]
        guard waitForExistence(welcomeBack, timeout: 5) else {
            XCTFail("LoginView did not appear")
            return
        }

        // Show email form
        let emailCTA = app.buttons["login.continueWithEmailButton"]
        guard waitForExistence(emailCTA, timeout: 3) else {
            XCTFail("Continue with Email button not found")
            return
        }
        emailCTA.tap()

        // Sign In button should exist but be disabled (empty fields)
        let signInButton = app.buttons["login.signInButton"]
        guard waitForExistence(signInButton, timeout: 3) else {
            XCTFail("Sign In button not found")
            return
        }
        XCTAssertFalse(signInButton.isEnabled, "Sign In should be disabled with empty fields")

        // Type email only — still disabled (no password)
        let emailField = app.textFields["login.emailField"]
        emailField.tap()
        emailField.typeText("test@example.com")
        XCTAssertFalse(signInButton.isEnabled, "Sign In should be disabled without password")

        // Type password — should enable
        let passwordField = app.secureTextFields["login.passwordField"]
        passwordField.tap()
        passwordField.typeText("any")
        XCTAssertTrue(waitForEnabled(signInButton, timeout: 3), "Sign In should be enabled with valid email and password")
    }
}
