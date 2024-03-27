//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import XCTest


final class AccountCreationTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["--showOnboarding", "--useFirebaseEmulator"]
        app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testAccountCreationFlow() {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to the account creation screen.
        app.buttons["Create Account"].tap()
        
        // Enter a valid invitation code.

        // Fill out the sign-up form.
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("example@stanford.edu")

        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("")

        // Submit the form.
        app.buttons["Submit"].tap()

        // Add assertions to verify the account was created successfully
        // Verify that the sheet is dismissed, thereby navigating to ECG list view.
    }
}
