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
        
        continueAfterFailure = false
        
        let app = XCUIApplication()
        app.launchArguments = ["--showOnboarding"]
        app.deleteAndLaunch(withSpringboardAppName: "PAWS")
    }
    
    
    func testOnboardingFlow() throws {
        let app = XCUIApplication()
        
        try app.navigateOnboardingFlow(assertThatHealthKitConsentIsShown: true)
        
        let tabBar = app.tabBars["Tab Bar"]
        XCTAssertTrue(tabBar.buttons["Notifications"].waitForExistence(timeout: 2))
        XCTAssertTrue(tabBar.buttons["Contacts"].waitForExistence(timeout: 2))
        XCTAssertTrue(tabBar.buttons["Mock Upload"].waitForExistence(timeout: 2))
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
        
        XCTAssertTrue(staticTexts["Given Name"].waitForExistence(timeout: 2))
        staticTexts["Given Name"].tap()
        textFields["Enter your given name ..."].typeText("Leland")
        
        XCTAssertTrue(staticTexts["Family Name"].waitForExistence(timeout: 2))
        staticTexts["Family Name"].tap()
        textFields["Enter your family name ..."].typeText("Stanford")
        
        textFields["Enter your family name ..."].typeText("\n")
        swipeUp()
        
        XCTAssertTrue(staticTexts["Leland Stanford"].waitForExistence(timeout: 2))
        staticTexts["Leland Stanford"].firstMatch.swipeUp()
        
        XCTAssertTrue(buttons["I Consent"].waitForExistence(timeout: 2))
        buttons["I Consent"].tap()
    }
    
    private func navigateOnboardingFlowHealthKitAccess(assertThatHealthKitConsentIsShown: Bool = true) throws {
        XCTAssertTrue(staticTexts["Health Data Access"].waitForExistence(timeout: 2))
        
        XCTAssertTrue(buttons["Grant Access"].waitForExistence(timeout: 2))
        
        buttons["Grant Access"].tap()
        
        try handleHealthKitAuthorization()
    }
}
