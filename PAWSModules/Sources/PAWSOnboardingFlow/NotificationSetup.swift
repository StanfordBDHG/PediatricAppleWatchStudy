//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable all

import Onboarding
import PAWSSharedContext
import SwiftUI

struct NotificationSetup: View {
    @Binding var onboardingSteps: [OnboardingFlow.Step]
    @AppStorage(StorageKeys.onboardingFlowComplete) var completedOnboardingFlow = false
    @State private var date = Date()
    @State private var selectedTime = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!
    
    var body: some View {
        OnboardingView(
            contentView: {
                VStack {
                    Image(systemName: "pawprint.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.red)
                        .offset(y: 20)
                    OnboardingTitleView(
                        title: "NOTIFICATION_SETUP_TITLE".moduleLocalized,
                        subtitle: "NOTIFICATION_SETUP_SUBTITLE".moduleLocalized
                    )
                    DatePicker("Select a time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    Image("NotificationImage")
                       .resizable()
                       .aspectRatio(contentMode: .fit)
                       .frame(width: 275, height: 275)
                       .padding(.vertical)
                    
                }
            }, actionView: {
                OnboardingActionsView(
                    "ALLOW_NOTIFICATIONS_BUTTON".moduleLocalized,
                    action: {
                        notificationTrigger()
                        completedOnboardingFlow = true
                    }
                )
            }
        )
    }
    
    func notificationTrigger() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Error scheduling notification: \(error)")
            } else {
                let content = UNMutableNotificationContent()
                content.title = "Friendly reminder to record your ECG!"
                content.body = "Thank you for participating in the PAWS study!"
                
                // Configure the recurring date.
                
                let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                
                for index in 0...6 {
                    let scheduleDate = Date.now.addingTimeInterval(86400 * Double(index))
                    guard let notificationDate = Calendar.current.nextDate(after: scheduleDate, matching: dateComponents, matchingPolicy: .nextTime) else {
                        continue
                    }
                    
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: notificationDate.timeIntervalSince(.now), repeats: false)
                    
                    
                    // Create the request
                    let uuidString = UUID().uuidString
                    let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
                    
                    // Schedule the request with the system.
                    let notificationCenter = UNUserNotificationCenter.current()
                    notificationCenter.add(request) { (error) in
                        if error != nil {
                            // Handle any errors.
                        }
                    }
                }
            }
        }
    }
    
}
