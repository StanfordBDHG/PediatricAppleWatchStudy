//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

@_spi(TestingSupport) import SpeziAccount
import SpeziOnboarding
import SwiftUI


struct AccountOnboarding: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    @AppStorage(StorageKeys.healthKitStartDate) var healthKitStartDate: Date?
    
    
    var body: some View {
        AccountSetup { details in
            healthKitStartDate = details.dateOfEnrollment
            
            Task {
                // Placing the nextStep() call inside this task will ensure that the sheet dismiss animation is
                // played till the end before we navigate to the next step.
                onboardingNavigationPath.nextStep()
            }
        } header: {
            AccountSetupHeader()
        } continue: {
            OnboardingActionsView(
                "ACCOUNT_NEXT",
                action: {
                    onboardingNavigationPath.nextStep()
                }
            )
        }
    }
}


#if DEBUG
#Preview("Account Onboarding SignIn") {
    OnboardingStack {
        AccountOnboarding()
    }
        .previewWith {
            AccountConfiguration(service: InMemoryAccountService())
        }
}

#Preview("Account Onboarding") {
    var details = AccountDetails()
    details.userId = "lelandstanford@stanford.edu"
    details.name = PersonNameComponents(givenName: "Leland", familyName: "Stanford")

    return OnboardingStack {
        AccountOnboarding()
    }
        .previewWith {
            AccountConfiguration(service: InMemoryAccountService(), activeDetails: details)
        }
}
#endif
