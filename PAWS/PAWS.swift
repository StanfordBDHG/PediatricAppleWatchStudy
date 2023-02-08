//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import CardinalKit
import PAWSOnboardingFlow
import PAWSSharedContext
import SwiftUI


@main
struct PAWS: App {
    @UIApplicationDelegateAdaptor(PAWSAppDelegate.self) var appDelegate
    @AppStorage(StorageKeys.onboardingFlowComplete) var completedOnboardingFlow = false
//    @AppStorage(StorageKeys.accountCreated) var completedAccountSetup = false

    
    
    var body: some Scene {
        WindowGroup {
//            if  completedAccountSetup {
                HomeView()
                    .sheet(isPresented: !$completedOnboardingFlow) {
                        OnboardingFlow()
                    }
                    .testingSetup()
                .cardinalKit(appDelegate)
//            } else {
//                /*@START_MENU_TOKEN@*/EmptyView()/*@END_MENU_TOKEN@*/
//            }
        }
    }
}
