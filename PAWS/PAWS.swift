//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import CardinalKit
import PAWSHomeScreen
import PAWSLandingScreen
import PAWSOnboardingFlow
import PAWSSharedContext
import SwiftUI

@main
struct PAWS: App {
    @UIApplicationDelegateAdaptor(PAWSAppDelegate.self) var appDelegate
    @AppStorage(StorageKeys.onboardingFlowComplete) var completedOnboardingFlow = false

    @State var pressedStart = false
    
    init() {
        let content = UNMutableNotificationContent()
        content.title = "Your friendly reminder to Record your ECG!"
        content.body = "Everyday at 7pm"
        // Configure the recurring date.
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current

        dateComponents.hour = 19    // 19:00 hours (7PM)
           
        // Create the trigger as a repeating event.
        let trigger = UNCalendarNotificationTrigger(
                 dateMatching: dateComponents, repeats: true)

        // Create the request
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString,
                    content: content, trigger: trigger)

        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
           if error != nil {
              // Handle any errors.
           }
        }
    }
    
    var isSheetPresented: Binding<Bool> {
        Binding(
            get: {
                !completedOnboardingFlow && pressedStart
            }, set: { _ in }
        )
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if completedOnboardingFlow {
                    HomeView()
                } else {
                    LandingScreen(pressedStart: $pressedStart)
                }
            }
                .sheet(isPresented: isSheetPresented) {
                    OnboardingFlow()
                        .interactiveDismissDisabled(true)
                }
                .testingSetup()
                .cardinalKit(appDelegate)
        }
    }
}
