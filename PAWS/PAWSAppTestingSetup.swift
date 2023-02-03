//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import PAWSSharedContext
import SwiftUI


private struct PAWSTestingSetup: ViewModifier {
    @AppStorage(StorageKeys.onboardingFlowComplete) var completedOnboardingFlow = false
    
    
    func body(content: Content) -> some View {
        content
            .task {
                if CommandLine.arguments.contains("--skipOnboarding") {
                    completedOnboardingFlow = true
                }
                if CommandLine.arguments.contains("--showOnboarding") {
                    completedOnboardingFlow = false
                }
            }
    }
}


extension View {
    func testingSetup() -> some View {
        self.modifier(PAWSTestingSetup())
    }
}
