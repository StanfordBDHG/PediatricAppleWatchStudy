//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Onboarding
import PAWSSharedContext
import SwiftUI


struct Consent: View {
    @Binding private var onboardingSteps: [OnboardingFlow.Step]
    
    
    private var consentDocument: Data {
        guard let path = Bundle.module.url(forResource: "ConsentDocument", withExtension: "md"),
              let data = try? Data(contentsOf: path) else {
            return Data("CONSENT_LOADING_ERROR".moduleLocalized.utf8)
        }
        return data
    }
    
    var body: some View {
        VStack {
            Image(systemName: "pawprint.circle.fill")
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .foregroundColor(.red)
                .offset(y: 10)
            ConsentView(
                header: {
                    OnboardingTitleView(
                        title: "CONSENT_TITLE".moduleLocalized,
                        subtitle: "CONSENT_SUBTITLE".moduleLocalized
                    )
                },
                
                asyncMarkdown: {
                    consentDocument
                },
                action: {
                    if !FeatureFlags.disableFirebase {
                        onboardingSteps.append(.accountSetup)
                    } else {
                        onboardingSteps.append(.healthKitPermissions)
                    }
                }
            )
            .offset(y: -20)
        }
    }
    
    
    init(onboardingSteps: Binding<[OnboardingFlow.Step]>) {
        self._onboardingSteps = onboardingSteps
    }
}


struct Consent_Previews: PreviewProvider {
    @State private static var path: [OnboardingFlow.Step] = []
    
    
    static var previews: some View {
        Consent(onboardingSteps: $path)
    }
}
