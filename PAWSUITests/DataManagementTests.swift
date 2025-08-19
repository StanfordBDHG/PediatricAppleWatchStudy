//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTHealthKit


final class DataManagementTests: XCTestCase {
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
    
    @MainActor
    func testPullToRefresh() async throws {
        let app = XCUIApplication()
        try app.navigateOnboardingFlow(email: "lelandstanford\(Int.random(in: 0...42000))@stanford.edu", code: "XKDYV3DF")
        
        let healthApp = XCUIApplication.healthApp
        try launchAndAddSample(healthApp: healthApp, .electrocardiogram())
        app.activate()
        
        let initialECGText = app.staticTexts["ECG Recording"]
        XCTAssertTrue(initialECGText.waitForExistence(timeout: 2))
        
        // Simulate pull to refresh.
        try await Task.sleep(for: .seconds(2))
        let ecgTableView = app.scrollViews.firstMatch
        XCTAssertTrue(ecgTableView.waitForExistence(timeout: 2))
        
        // Allow some time for the refresh to complete.
        try await Task.sleep(for: .seconds(5))
        
        ecgTableView.press(forDuration: 0, thenDragTo: app.tabBars.firstMatch)
        
        // Allow some time for the refresh to complete.
        try await Task.sleep(for: .seconds(1))
        
        // Validate that the same ECG is still present after the refresh.
        let refreshedECGText = app.staticTexts["ECG Recording"]
        XCTAssertTrue(refreshedECGText.waitForExistence(timeout: 2))
        XCTAssertEqual(initialECGText.description, refreshedECGText.description)
        
        // Now return to the Health app, and add some more ECGs before capturing a screenshot (for App Store).
        for _ in 0..<4 where UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
            try launchAndAddSample(healthApp: healthApp, .electrocardiogram())
        }
        
        app.activate()
        
        PAWSUITests.snapshot("2Home")
    }
}
