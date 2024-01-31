//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SpeziScheduler
import SwiftUI


struct NotificationPermissions: View {
    @Environment(PAWSScheduler.self) private var scheduler
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    
    @State private var notificationProcessing = false
    @State private var selectedTime = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: .now) ?? .now
    
    
    var body: some View {
        OnboardingView(
            contentView: {
                VStack {
                    Image(systemName: "pawprint.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(Color.accentColor)
                        .offset(y: 20)
                        .accessibilityHidden(true)
                    OnboardingTitleView(
                        title: "NOTIFICATIONS_TITLE",
                        subtitle: "NOTIFICATIONS_SUBTITLE"
                    )
                    DatePicker("Select a time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    Image("NotificationImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 275, height: 275)
                        .padding(.vertical)
                        .accessibilityHidden(true)
                }
            }, actionView: {
                OnboardingActionsView(
                    "NOTIFICATION_PERMISSIONS_BUTTON",
                    action: {
                        do {
                            notificationProcessing = true
                            
                            let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                            try await scheduler.scheduleReminders(time: dateComponents)
                            
                            // Notification Authorization is not available in the preview simulator.
                            if ProcessInfo.processInfo.isPreviewSimulator {
                                try await _Concurrency.Task.sleep(for: .seconds(5))
                            } else {
                                try await scheduler.requestLocalNotificationAuthorization()
                            }
                        } catch {
                            print("Could not request notification permissions.")
                        }
                        notificationProcessing = false
                        
                        onboardingNavigationPath.nextStep()
                    }
                )
            }
        )
            .navigationBarBackButtonHidden(notificationProcessing)
            // Small fix as otherwise "Login" or "Sign up" is still shown in the nav bar
            .navigationTitle(Text(verbatim: ""))
    }
}


#if DEBUG
#Preview {
    OnboardingStack {
        NotificationPermissions()
    }
        .previewWith {
            PAWSScheduler()
        }
}
#endif
