//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import XCTest


class ContactsTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
        
        let app = XCUIApplication()
        app.launchArguments = ["--skipOnboarding"]
        app.launch()
    }
    
    
    func testContacts() throws {
        let app = XCUIApplication()
        
        XCTAssertTrue(app.tabBars["Tab Bar"].buttons["Study Information"].waitForExistence(timeout: 2))
        app.tabBars["Tab Bar"].buttons["Study Information"].tap()
        
        XCTAssertTrue(app.staticTexts["Scott Ceresnak"].waitForExistence(timeout: 2))
        
        app.swipeUp(velocity: .fast)
        
        XCTAssertTrue(app.staticTexts["Aydin Zahedivash"].waitForExistence(timeout: 2))
    }
}
