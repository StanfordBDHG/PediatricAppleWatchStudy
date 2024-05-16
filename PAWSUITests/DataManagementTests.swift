//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import XCTest

final class DataManagementTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--showOnboarding", "--useFirebaseEmulator"]
        app.deleteAndLaunch(withSpringboardAppName: "PAWS")
    }
    
    func testPullToRefresh() throws {
        let app = XCUIApplication()
        try app.navigateOnboardingFlow(email: "johndoe@stanford.edu")
        
        try self.exitAppAndOpenHealth(.electrocardiograms)
        app.activate()
        
        XCTAssertTrue(app.staticTexts["ECG Recording"].waitForExistence(timeout: 2))
        
        // Simulate pull to refresh.
        let start = app.scrollViews.firstMatch.coordinate(withNormalizedOffset: .zero)
        let finish = start.withOffset(CGVector(dx: 0, dy: 200))
        start.press(forDuration: 0, thenDragTo: finish)
        
        // Allow some time for the refresh to complete.
        sleep(2)
        
        // Validate that the same ECG is still present after the refresh.
        XCTAssertTrue(app.staticTexts["ECG Recording"].waitForExistence(timeout: 2))
    }
}
