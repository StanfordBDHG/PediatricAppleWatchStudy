//
//  DataManagementTests.swift
//  PAWSUITests
//
//  Created by Matthew Turk on 5/15/24.
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
        let initialECGCount = app.staticTexts["ECG Recording"].exists
        
        try self.exitAppAndOpenHealth(.electrocardiograms)
        app.activate()
        
        // Simulate pull to refresh.
        let start = app.scrollViews.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let finish = start.withOffset(CGVector(dx: 0, dy: 200))
        start.press(forDuration: 0, thenDragTo: finish)
        
        // Allow some time for the refresh to complete.
        sleep(2)
        
        // Validate that the ECG list has been updated.
        let refreshedECGCount = app.staticTexts["ECG Recording"].exists
        XCTAssertFalse(initialECGCount)
        XCTAssertTrue(refreshedECGCount)
    }
}
