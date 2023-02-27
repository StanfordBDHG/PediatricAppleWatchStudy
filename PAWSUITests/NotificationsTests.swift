//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import XCTest


class NotificationsTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
        
        let app = XCUIApplication()
        app.launchArguments = ["--skipOnboarding"]
        app.launch()
    }
    
    
    func testNotifications() throws {
        let app = XCUIApplication()
        
        XCTAssertTrue(app.tabBars["Tab Bar"].buttons["Reports"].waitForExistence(timeout: 2))
        app.tabBars["Tab Bar"].buttons["Reports"].tap()
                
        app.swipeUp(velocity: .fast)
    }
}
