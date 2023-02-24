//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import PAWSSharedContext
import SwiftUI


/// Displays an multi-step onboarding flow for the CS342 2023 PAWS Team Application.
public struct OnboardingFlow: View {
    enum Step: String, Codable {
        case interestingModules
        case consent
        case accountSetup
        case login
        case signUp
        case healthKitPermissions
    }
    
    
    @SceneStorage(StorageKeys.onboardingFlowStep) private var onboardingSteps: [Step] = []
    
    
    public var body: some View {
        VStack {
            NavigationStack(path: $onboardingSteps) {
                Image(systemName: "pawprint.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.red)
                    .offset(y: 20)
                Welcome(onboardingSteps: $onboardingSteps)
                    .navigationDestination(for: Step.self) { onboardingStep in
                        switch onboardingStep {
                        case .interestingModules:
                            InterestingModules(onboardingSteps: $onboardingSteps)
                        case .accountSetup:
                            AccountSetup(onboardingSteps: $onboardingSteps)
                        case .login:
                            PAWSLogin()
                        case .signUp:
                            PAWSSignUp()
                        case .consent:
                            Consent(onboardingSteps: $onboardingSteps)
                        case .healthKitPermissions:
                            HealthKitPermissions()
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    
    public init() {}
}


struct OnboardingFlow_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFlow()
    }
}
