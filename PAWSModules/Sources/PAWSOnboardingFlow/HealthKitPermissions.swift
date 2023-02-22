//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FHIR
import HealthKitDataSource
import Onboarding
import PAWSSharedContext
import SwiftUI


struct HealthKitPermissions: View {
    @EnvironmentObject var healthKitDataSource: HealthKit<FHIR>
    @AppStorage(StorageKeys.onboardingFlowComplete) var completedOnboardingFlow = false
    
    
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
                        title: "HEALTHKIT_PERMISSIONS_TITLE".moduleLocalized,
                        subtitle: "HEALTHKIT_PERMISSIONS_SUBTITLE".moduleLocalized
                    )
                    Spacer()
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 150))
                        .foregroundColor(.accentColor)
                    Text("HEALTHKIT_PERMISSIONS_DESCRIPTION", bundle: .module)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 16)
                    Spacer()
                }
            }, actionView: {
                OnboardingActionsView(
                    "HEALTHKIT_PERMISSIONS_BUTTON".moduleLocalized,
                    action: {
                        do {
                            try await healthKitDataSource.askForAuthorization()
                        } catch {
                            print("Could not request HealthKit permissions.")
                        }
                        completedOnboardingFlow = true
                    }
                )
            }
        )
    }
}


struct HealthKitPermissions_Previews: PreviewProvider {
    static var previews: some View {
        HealthKitPermissions()
    }
}
