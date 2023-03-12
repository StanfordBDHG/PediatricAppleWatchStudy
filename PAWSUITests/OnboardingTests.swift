//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTestExtensions
import XCTHealthKit


class OnboardingTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        try disablePasswordAutofill()
        
        continueAfterFailure = false
        
        let app = XCUIApplication()
        app.launchArguments = ["--showOnboarding"]
        app.deleteAndLaunch(withSpringboardAppName: "PAWS")
    }
    
    
    func testOnboardingFlow() throws {
        let app = XCUIApplication()
        
        try app.navigateOnboardingFlow(assertThatHealthKitConsentIsShown: true)
        
        let tabBar = app.tabBars["Tab Bar"]
        XCTAssertTrue(tabBar.buttons["Study Information"].waitForExistence(timeout: 2))
        XCTAssertTrue(tabBar.buttons["Reports"].waitForExistence(timeout: 2))
    }
}


extension XCUIApplication {
    func conductOnboardingIfNeeded() throws {
        if buttons["Tap to get started"].waitForExistence(timeout: 2) {
            try navigateOnboardingFlow(assertThatHealthKitConsentIsShown: false)
        }
    }
    
    func navigateOnboardingFlow(assertThatHealthKitConsentIsShown: Bool = true) throws {
        try navigateOnboardingGetStarted()
        try navigateOnboardingFlowWelcome()
        try navigateOnboardingFlowInterestingModules()
        if staticTexts["Consent Page"].waitForExistence(timeout: 2) {
            try navigateOnboardingFlowConsent()
        }
        try navigateOnboardingAccount()
        try navigateOnboardingFlowHealthKitAccess(assertThatHealthKitConsentIsShown: assertThatHealthKitConsentIsShown)
    }
    
    private func navigateOnboardingGetStarted() throws {
        XCTAssertTrue(buttons["Tap to get started"].waitForExistence(timeout: 2))
        buttons["Tap to get started"].tap()
    }
    
    private func navigateOnboardingFlowWelcome() throws {
        XCTAssertTrue(staticTexts["Welcome to PAWS!"].waitForExistence(timeout: 2))
        
        swipeUp()
        
        XCTAssertTrue(buttons["Begin onboarding"].waitForExistence(timeout: 2))
        buttons["Begin onboarding"].tap()
    }
    
    private func navigateOnboardingFlowInterestingModules() throws {
        XCTAssertTrue(staticTexts["PAWS Onboarding"].waitForExistence(timeout: 2))
        
        for _ in 1..<3 {
            XCTAssertTrue(buttons["Next"].waitForExistence(timeout: 2))
            buttons["Next"].tap()
        }
        
        XCTAssertTrue(buttons["Next"].waitForExistence(timeout: 2))
        buttons["Next"].tap()
    }
    
    private func navigateOnboardingFlowConsent() throws {
        XCTAssertTrue(staticTexts["Consent Page"].waitForExistence(timeout: 2))
        
        swipeUp(velocity: .fast)
        
        XCTAssertTrue(staticTexts["First Name"].waitForExistence(timeout: 2))
        staticTexts["First Name"].tap()
        textFields["Enter your first name ..."].typeText("Leland")
        
        XCTAssertTrue(staticTexts["Last Name"].waitForExistence(timeout: 2))
        staticTexts["Last Name"].tap()
        textFields["Enter your last name ..."].typeText("Stanford")
        
        textFields["Enter your last name ..."].typeText("\n")
        swipeUp()
        
        XCTAssertTrue(staticTexts["Leland Stanford"].waitForExistence(timeout: 2))
        staticTexts["Leland Stanford"].firstMatch.swipeUp()
        
        XCTAssertTrue(buttons["I Consent"].waitForExistence(timeout: 2))
        buttons["I Consent"].tap()
    }
    
    private func navigateOnboardingAccount() throws {
        XCTAssertTrue(staticTexts["Your PAWS Account"].waitForExistence(timeout: 2))
        
        guard !buttons["Next"].waitForExistence(timeout: 5) else {
            buttons["Next"].tap()
            return
        }
        
        XCTAssertTrue(buttons["Sign Up"].waitForExistence(timeout: 2))
        buttons["Sign Up"].tap()
        
        XCTAssertTrue(navigationBars.staticTexts["Sign Up"].waitForExistence(timeout: 2))
        XCTAssertTrue(images["App Icon"].waitForExistence(timeout: 2))
        XCTAssertTrue(buttons["Email and Password"].waitForExistence(timeout: 2))
        
        buttons["Email and Password"].tap()
        
        try textFields["Enter your email ..."].enter(value: "leland@stanford.edu")
        swipeUp()
        
        secureTextFields["Enter your password ..."].tap()
        secureTextFields["Enter your password ..."].typeText("StanfordRocks")
        swipeUp()
        secureTextFields["Repeat your password ..."].tap()
        secureTextFields["Repeat your password ..."].typeText("StanfordRocks")
        swipeUp()
        
        try textFields["Enter your first name ..."].enter(value: "Leland")
        staticTexts["Repeat\nPassword"].swipeUp()
        
        try textFields["Enter your last name ..."].enter(value: "Stanford")
        staticTexts["Repeat\nPassword"].swipeUp()
        
        collectionViews.buttons["Sign Up"].tap()
        
        sleep(3)
        
        if staticTexts["HealthKit Access"].waitForExistence(timeout: 5) && navigationBars.buttons["Back"].waitForExistence(timeout: 5) {
            navigationBars.buttons["Back"].tap()
            
            XCTAssertTrue(staticTexts["Leland Stanford"].waitForExistence(timeout: 2))
            XCTAssertTrue(staticTexts["leland@stanford.edu"].waitForExistence(timeout: 2))
            
            XCTAssertTrue(scrollViews.otherElements.buttons["Next"].waitForExistence(timeout: 2))
            scrollViews.otherElements.buttons["Next"].tap()
        }
    }
    
    private func navigateOnboardingFlowHealthKitAccess(assertThatHealthKitConsentIsShown: Bool = true) throws {
        XCTAssertTrue(staticTexts["Health Data Access"].waitForExistence(timeout: 2))
        
        XCTAssertTrue(buttons["Grant Access"].waitForExistence(timeout: 2))
        
        buttons["Grant Access"].tap()
        
        try handleHealthKitAuthorization()
    }
}
