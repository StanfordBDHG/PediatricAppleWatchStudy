//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziAccount
import SpeziFirebaseAccount
import SpeziFirebaseStorage
import SpeziFirestore
import SpeziHealthKit
import SpeziMockWebService
import SpeziOnboarding
import SpeziScheduler
import SwiftUI


class PAWSDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: PAWSStandard()) {
            if !FeatureFlags.disableFirebase {
                AccountConfiguration(configuration: [
                    .requires(\.userId),
                    .requires(\.name),
                    .requires(\.dateOfBirth),
                    .collects(\.genderIdentity)
                ])

                if FeatureFlags.useFirebaseEmulator {
                    FirebaseAccountConfiguration(
                        authenticationMethods: [.emailAndPassword, .signInWithApple],
                        emulatorSettings: (host: "localhost", port: 9099)
                    )
                } else {
                    FirebaseAccountConfiguration(authenticationMethods: [.emailAndPassword, .signInWithApple])
                }
                firestore
                if FeatureFlags.useFirebaseEmulator {
                    FirebaseStorageConfiguration(emulatorSettings: (host: "localhost", port: 9199))
                } else {
                    FirebaseStorageConfiguration()
                }
            } else {
                MockWebService()
            }

            if HKHealthStore.isHealthDataAvailable() {
                healthKit
            }
            
            PAWSScheduler()
            OnboardingDataSource()
        }
    }
    
    
    private var firestore: Firestore {
        let settings = FirestoreSettings()
        if FeatureFlags.useFirebaseEmulator {
            settings.host = "localhost:8080"
            settings.cacheSettings = MemoryCacheSettings()
            settings.isSSLEnabled = false
        }
        
        return Firestore(
            settings: settings
        )
    }
    
    
    private var healthKit: HealthKit {
        @AppStorage(StorageKeys.healthKitStartDate) var healthKitStartDate: Date = .now
        
        // Collection starts at the time the user consents and lasts for 1 month.
        let sharedPredicate = HKQuery.predicateForSamples(
            withStart: healthKitStartDate,
            end: Calendar.current.date(byAdding: DateComponents(month: 1), to: healthKitStartDate),
            options: .strictEndDate
        )
        
        return HealthKit {
            CollectSample(
                HKQuantityType.electrocardiogramType(),
                predicate: sharedPredicate,
                deliverySetting: .background(saveAnchor: false)
            )
            CollectSamples(
                Set(HKElectrocardiogram.correlatedSymptomTypes),
                predicate: sharedPredicate,
                deliverySetting: .background(saveAnchor: false)
            )
        }
    }
}
