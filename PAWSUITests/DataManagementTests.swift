//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import XCTest

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
    
    func testPullToRefresh() throws {
        let app = XCUIApplication()
        try app.navigateOnboardingFlow(email: "lelandstanford\(Int.random(in: 0...42000))@stanford.edu", code: "XKDYV3DF")
        
        try self.exitAppAndOpenHealth(.electrocardiograms)
        app.activate()
        
        let initialECGText = app.staticTexts["ECG Recording"]
        XCTAssertTrue(initialECGText.waitForExistence(timeout: 2))
        
        // Simulate pull to refresh.
        let ecgTableView = app.scrollViews.firstMatch
        XCTAssertTrue(ecgTableView.waitForExistence(timeout: 2))
        ecgTableView.press(forDuration: 0, thenDragTo: app.tabBars.firstMatch)
        
        // Allow some time for the refresh to complete.
        sleep(2)
        
        // Validate that the same ECG is still present after the refresh.
        let refreshedECGText = app.staticTexts["ECG Recording"]
        XCTAssertTrue(refreshedECGText.waitForExistence(timeout: 2))
        XCTAssertEqual(initialECGText.description, refreshedECGText.description)
        
        // Now return to the Health app, and add some more ECGs before capturing a screenshot (for App Store).
        for _ in 0..<4 where UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
            try self.exitAppAndOpenHealth(.electrocardiograms)
        }
        
        app.activate()
        
        Task {
            await PAWSUITests.snapshot("2Home")
        }
    }
}
