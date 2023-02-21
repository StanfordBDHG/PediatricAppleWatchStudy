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


class HealthKitUploadTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
        
        let app = XCUIApplication()
        app.launchArguments = ["--showOnboarding"]
        app.deleteAndLaunch(withSpringboardAppName: "PAWS")
    }
    
    
    func testHealthKitMockUpload() throws {
        let app = XCUIApplication()
        
        try app.conductOnboardingIfNeeded()
        
        try app.navigateToMockUpload()
        try app.assertObservationCellPresent(false)
        
        try exitAppAndOpenHealth(.electrocardiograms)
        
        app.activate()
        
        sleep(5)
        
        try app.navigateToMockUpload()
        try app.assertObservationCellPresent(true, pressIfPresent: true)
        try app.assertObservationCellPresent(true, pressIfPresent: false)
    }
}

extension XCUIApplication {
    fileprivate func navigateToMockUpload() throws {
        XCTAssertTrue(tabBars["Tab Bar"].buttons["Mock Upload"].waitForExistence(timeout: 2))
        tabBars["Tab Bar"].buttons["Mock Upload"].tap()
    }
    
    fileprivate func assertObservationCellPresent(_ shouldBePresent: Bool, pressIfPresent: Bool = true) throws {
        let observationText = "/Observation/"
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", observationText)
        
        if shouldBePresent {
            XCTAssertTrue(staticTexts.containing(predicate).firstMatch.waitForExistence(timeout: 2))
            if pressIfPresent {
                staticTexts.containing(predicate).firstMatch.tap()
            }
        } else {
            XCTAssertFalse(staticTexts.containing(predicate).firstMatch.waitForExistence(timeout: 2))
        }
    }
}
