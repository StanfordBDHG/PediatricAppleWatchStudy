//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SwiftUI


/// - Note: The `OnboardingConsentView` exports the signed consent form as PDF to the Spezi `Standard`, necessitating the conformance of the `Standard` to the `OnboardingConstraint`.
struct Consent: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    // periphery:ignore - The periphery warning here is a false positive, the value us stored using @AppStorage.
    @AppStorage(StorageKeys.healthKitStartDate) var healthKitStartDate: Date?
    
    
    private var consentDocument: Data {
        guard let path = Bundle.main.url(forResource: "ConsentDocument", withExtension: "md"),
              let data = try? Data(contentsOf: path) else {
            return Data(String(localized: "CONSENT_LOADING_ERROR").utf8)
        }
        return data
    }
    
    
    var body: some View {
        OnboardingConsentView(
            markdown: {
                consentDocument
            },
            action: {
                healthKitStartDate = Date.now
                onboardingNavigationPath.nextStep()
            }
        )
    }
}


#if DEBUG
#Preview {
    OnboardingStack {
        Consent()
    }
        .previewWith(standard: PAWSStandard()) {
            OnboardingDataSource()
        }
}
#endif
