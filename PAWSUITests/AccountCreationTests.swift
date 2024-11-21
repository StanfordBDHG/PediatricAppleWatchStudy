//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTestExtensions
import XCTHealthKit


final class AccountCreationTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false

        let app = await XCUIApplication()
        await setupSnapshot(app)

        await MainActor.run {
            app.launchArguments = ["--showOnboarding", "--useFirebaseEmulator"]
        }
        await app.deleteAndLaunch(withSpringboardAppName: "PAWS")
    }
    
    func testOnboardingFlow() throws {
        let app = XCUIApplication()
        let email = "lelandstanford\(Int.random(in: 0...42000))@stanford.edu"
        
        try app.navigateOnboardingFlow(email: email, code: "QDXRWF6G")

        app.assertOnboardingComplete()
        app.assertStudyGroupAdult()
        try app.assertAccountInformation(email: email)
    }
}

extension XCUIApplication {
    func navigateOnboardingFlow(
        email: String = "lelandstanford\(Int.random(in: 0...42000))@stanford.edu",
        code: String = "QDXRWF6G",
        repeated skippedIfRepeated: Bool = false
    ) throws {
        try navigateOnboardingFlowWelcome()
        try navigateOnboardingFlowInterestingModules()
        try navigateOnboardingInvitationCode(code: code)
        if staticTexts["Your PAWS Account"].waitForExistence(timeout: 5) {
            try navigateOnboardingAccount(email: email)
        }
        if staticTexts["Consent"].waitForExistence(timeout: 5) {
            try navigateOnboardingFlowConsent()
        }
        if !skippedIfRepeated {
            try navigateOnboardingFlowHealthKitAccess()
            try navigateOnboardingFlowNotification()
        }
    }
    
    private func navigateOnboardingFlowWelcome() throws {
        XCTAssertTrue(staticTexts["Welcome to PAWS!"].waitForExistence(timeout: 5))
        
        XCTAssertTrue(buttons["Learn More"].waitForExistence(timeout: 2))
        buttons["Learn More"].tap()
    }
    
    private func navigateOnboardingFlowInterestingModules() throws {
        XCTAssertTrue(staticTexts["Interesting Modules"].waitForExistence(timeout: 5))
        
        for index in 1..<4 {
            XCTAssertTrue(buttons["Next"].waitForExistence(timeout: 2))
            buttons["Next"].tap()
            if index == 2 {
                PAWSUITests.snapshot("0Launch")
            }
        }
    }
    
    private func navigateOnboardingInvitationCode(code: String) throws {
        PAWSUITests.snapshot("1InvitationCode")
        let alternativeInvitationCodes = ["ALAAVMVB", "QKGCPEQQ"]
        try enterInvitationCode(withRemainingOptions: [code] + alternativeInvitationCodes)
    }
    
    private func enterInvitationCode(withRemainingOptions: [String]) throws {
        var withRemainingOptions = withRemainingOptions
        let invitationCode = withRemainingOptions.removeFirst()
        
        XCTAssertTrue(staticTexts["Invitation Code"].waitForExistence(timeout: 5))
        try textFields["Invitation Code"].enter(value: invitationCode)
        XCTAssertTrue(buttons["Redeem Invitation Code"].waitForExistence(timeout: 2))
        buttons["Redeem Invitation Code"].tap()
        
        let alert = alerts["Error"]
        if alert.waitForExistence(timeout: 3.0) {
            print("Warning: Initial invitation code is invalid, please esure to reset your simulator.")
            alert.buttons["OK"].tap()
            try textFields["Invitation Code"].delete(count: 8, options: .disableKeyboardDismiss)
            
            if !withRemainingOptions.isEmpty {
                try enterInvitationCode(withRemainingOptions: withRemainingOptions)
            } else {
                XCTFail("Failed to redeem invitation code.")
            }
        }
        
        sleep(3)
    }
    
    private func navigateOnboardingAccount(email: String) throws {
        if buttons["Logout"].waitForExistence(timeout: 2.0) {
            buttons["Logout"].tap()
        }
        
        XCTAssertTrue(buttons["Signup"].waitForExistence(timeout: 2))
        buttons["Signup"].tap()

        XCTAssertTrue(staticTexts["Create a new Account"].waitForExistence(timeout: 2))
        
        try collectionViews.textFields["E-Mail Address"].enter(value: email)
        try collectionViews.secureTextFields["Password"].enter(value: "HelloWorld")
        try textFields["enter first name"].enter(value: "Leland")
        try textFields["enter last name"].enter(value: "Stanford")
        let datePicker = datePickers.firstMatch
        XCTAssertTrue(datePicker.waitForExistence(timeout: 2))
        datePicker.tap()
        let dateButton = datePicker.buttons.firstMatch
        XCTAssertTrue(dateButton.waitForExistence(timeout: 2))
        dateButton.tap()
        let dateWheel = datePicker.pickerWheels.element(boundBy: 1)
        XCTAssertTrue(dateWheel.waitForExistence(timeout: 2))
        dateWheel.adjust(toPickerWheelValue: "1970")
        
        datePicker.tap()
        swipeUp()
        
        collectionViews.buttons["Signup"].tap()
        
        sleep(1)

        if collectionViews.buttons["Signup"].waitForExistence(timeout: 2) {
            collectionViews.buttons["Signup"].tap()
        }
        
        sleep(3)
    }
    
    private func navigateOnboardingFlowConsent() throws {
        XCTAssertTrue(staticTexts["Consent"].waitForExistence(timeout: 5))
        
        XCTAssertTrue(staticTexts["First Name"].waitForExistence(timeout: 2))
        try textFields["Enter your first name ..."].enter(value: "Leland")
        
        XCTAssertTrue(staticTexts["Last Name"].waitForExistence(timeout: 2))
        try textFields["Enter your last name ..."].enter(value: "Stanford")

        XCTAssertTrue(scrollViews["Signature Field"].waitForExistence(timeout: 2))
        scrollViews["Signature Field"].swipeRight()

        XCTAssertTrue(buttons["I Consent"].waitForExistence(timeout: 2))
        buttons["I Consent"].tap()
    }

    private func navigateOnboardingFlowHealthKitAccess() throws {
        XCTAssertTrue(staticTexts["HealthKit Access"].waitForExistence(timeout: 5))
        
        XCTAssertTrue(buttons["Health Data Access"].waitForExistence(timeout: 2))
        buttons["Health Data Access"].tap()
        
        XCTAssertTrue(navigationBars["Health Access"].waitForExistence(timeout: 10))
        tables.staticTexts["Turn On All"].tap()
        navigationBars["Health Access"].buttons["Allow"].tap()
    }
    
    private func navigateOnboardingFlowNotification() throws {
        XCTAssertTrue(staticTexts["PAWS Reminders"].waitForExistence(timeout: 5))
        
        XCTAssertTrue(buttons["Allow Notifications"].waitForExistence(timeout: 2))
        buttons["Allow Notifications"].tap()
        
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alertAllowButton = springboard.buttons["Allow"]
        if alertAllowButton.waitForExistence(timeout: 5) {
           alertAllowButton.tap()
        }
    }
    
    fileprivate func assertOnboardingComplete() {
        let tabBar = tabBars["Tab Bar"]
        XCTAssertTrue(tabBar.buttons["ECG Recordings"].waitForExistence(timeout: 2))
        XCTAssertTrue(tabBar.buttons["Infos"].waitForExistence(timeout: 2))
        XCTAssertTrue(tabBar.buttons["Contacts"].waitForExistence(timeout: 2))
    }
    
    fileprivate func assertStudyGroupAdult() {
        let tabBar = tabBars["Tab Bar"]
        XCTAssertTrue(tabBar.buttons["Contacts"].waitForExistence(timeout: 2))
        tabBar.buttons["Contacts"].tap()
        XCTAssertTrue(staticTexts["Contact: Brynn Connor"].waitForExistence(timeout: 2))
    }

    fileprivate func assertAccountInformation(email: String) throws {
        XCTAssertTrue(navigationBars.buttons["Your PAWS Account"].waitForExistence(timeout: 2))
        navigationBars.buttons["Your PAWS Account"].tap()

        XCTAssertTrue(staticTexts["Account Overview"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(staticTexts["Leland Stanford"].exists)
        XCTAssertTrue(staticTexts[email].exists)
        XCTAssertTrue(staticTexts["Gender Identity, Choose not to answer"].exists)
        PAWSUITests.snapshot("3AccountInformation")


        XCTAssertTrue(navigationBars.buttons["Close"].waitForExistence(timeout: 0.5))
        navigationBars.buttons["Close"].tap()

        XCTAssertTrue(navigationBars.buttons["Your PAWS Account"].waitForExistence(timeout: 2))
        navigationBars.buttons["Your PAWS Account"].tap()

        XCTAssertTrue(navigationBars.buttons["Edit"].waitForExistence(timeout: 2))
        navigationBars.buttons["Edit"].tap()

        usleep(500_00)
        XCTAssertFalse(navigationBars.buttons["Close"].exists)

        XCTAssertTrue(buttons["Delete Account"].waitForExistence(timeout: 2))
        buttons["Delete Account"].tap()

        let alert = "Are you sure you want to delete your account?"
        XCTAssertTrue(alerts[alert].waitForExistence(timeout: 6.0))
        alerts[alert].buttons["Delete"].tap()

        XCTAssertTrue(alerts["Authentication Required"].waitForExistence(timeout: 2.0))
        XCTAssertTrue(alerts["Authentication Required"].secureTextFields["Password"].waitForExistence(timeout: 0.5))
        typeText("HelloWorld") // the password field has focus already
        XCTAssertTrue(alerts["Authentication Required"].buttons["Login"].waitForExistence(timeout: 0.5))
        alerts["Authentication Required"].buttons["Login"].tap()

        sleep(2)

        // Login
        try textFields["E-Mail Address"].enter(value: email)
        try secureTextFields["Password"].enter(value: "HelloWorld")

        XCTAssertTrue(buttons["Login"].waitForExistence(timeout: 0.5))
        buttons["Login"].tap()

        XCTAssertTrue(alerts["Invalid Credentials"].waitForExistence(timeout: 2.0))
    }
}
