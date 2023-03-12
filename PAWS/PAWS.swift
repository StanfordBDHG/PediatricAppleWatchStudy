//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import CardinalKit
import PAWSLandingScreen
import PAWSMockDataStorageProvider
import PAWSOnboardingFlow
import PAWSSharedContext
import SwiftUI

@main
struct PAWS: App {
    @UIApplicationDelegateAdaptor(PAWSAppDelegate.self) var appDelegate
    @AppStorage(StorageKeys.onboardingFlowComplete) var completedOnboardingFlow = false

    @State var pressedStart = false
    
    init() {
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            
            if let error = error {
                // Handle the error here.
            }
            
            // Enable or disable features based on the authorization.
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Friendly reminder to record your ECG!"
        content.body = "Thank you for participating in the PAWS study!"

        // Configure the recurring date.
        
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current

        dateComponents.hour = 17    // 19:00 hours
        
        for index in 0...6 {
            let scheduleDate = Date.now.addingTimeInterval(86400 * Double(index))
            guard let notificationDate = Calendar.current.nextDate(after: scheduleDate, matching: dateComponents, matchingPolicy: .nextTime) else {
                return
            }
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: notificationDate.timeIntervalSince(.now), repeats: false)
            
            
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
