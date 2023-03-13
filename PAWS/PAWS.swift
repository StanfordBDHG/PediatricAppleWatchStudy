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
