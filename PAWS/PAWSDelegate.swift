//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseFirestore
import Spezi
import SpeziAccount
import SpeziFirebaseAccount
import SpeziFirebaseAccountStorage
import SpeziFirebaseStorage
import SpeziFirestore
import SpeziHealthKit
import SpeziOnboarding
import SpeziScheduler
import SwiftUI


class PAWSDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: PAWSStandard()) {
            if !FeatureFlags.disableFirebase {
                AccountConfiguration(
                    service: FirebaseAccountService(providers: [.emailAndPassword, .signInWithApple], emulatorSettings: accountEmulator),
                    storageProvider: FirestoreAccountStorage(
                        storeIn: Firestore.firestore().userCollectionReference,
                        mapping: [
                            "DateOfBirthKey": AccountKeys.dateOfBirth,
                            "GenderIdentityKey": AccountKeys.genderIdentity
                        ]
                    ),
                    configuration: [
                        .requires(\.userId),
                        .requires(\.name),
                        .requires(\.dateOfBirth),
                        .collects(\.genderIdentity)
                    ]
                )
                firestore
                if FeatureFlags.useFirebaseEmulator {
                    FirebaseStorageConfiguration(emulatorSettings: (host: "localhost", port: 9199))
                } else {
                    FirebaseStorageConfiguration()
                }
            }

            if HKHealthStore.isHealthDataAvailable() {
                healthKit
            }
            
            PAWSScheduler()
            OnboardingDataSource()
            EnrollmentGroup()
        }
    }
    
    private var accountEmulator: (host: String, port: Int)? {
        if FeatureFlags.useFirebaseEmulator {
            (host: "localhost", port: 9099)
        } else {
            nil
        }
    }
    
    private var firestore: SpeziFirestore.Firestore {
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
        
        // Collection starts at the time the user consents and lasts for 6 months.
        let sharedPredicate = HKQuery.predicateForSamples(
            withStart: healthKitStartDate,
            end: Calendar.current.date(byAdding: DateComponents(month: 6), to: healthKitStartDate),
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
                deliverySetting: .background(saveAnchor: true)
            )
            CollectSample(
                HKQuantityType(.heartRate),
                predicate: sharedPredicate,
                deliverySetting: .manual(safeAnchor: false)
            )
            CollectSample(
                HKQuantityType(.vo2Max),
                predicate: sharedPredicate,
                deliverySetting: .manual(safeAnchor: false)
            )
            CollectSample(
                HKQuantityType(.physicalEffort),
                predicate: sharedPredicate,
                deliverySetting: .manual(safeAnchor: false)
            )
            CollectSample(
                HKQuantityType(.stepCount),
                predicate: sharedPredicate,
                deliverySetting: .manual(safeAnchor: false)
            )
            CollectSample(
                HKQuantityType(.activeEnergyBurned),
                predicate: sharedPredicate,
                deliverySetting: .manual(safeAnchor: false)
            )
        }
    }
}
