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
                            "GenderIdentityKey": AccountKeys.genderIdentity,
                            "dateOfEnrollment": AccountKeys.dateOfEnrollment
                        ]
                    ),
                    configuration: [
                        .requires(\.userId),
                        .requires(\.name),
                        .requires(\.dateOfBirth),
                        .collects(\.genderIdentity),
                        .supports(\.dateOfEnrollment)
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
            
            Scheduler()
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
            CollectSample(.electrocardiogram, continueInBackground: true, predicate: sharedPredicate)
            for correlatedSymptomType in HKElectrocardiogram.correlatedSymptomTypes {
                CollectSample(correlatedSymptomType, continueInBackground: true, predicate: sharedPredicate)
            }
            RequestReadAccess(
                quantity: [.heartRate, .vo2Max, .physicalEffort, .stepCount, .activeEnergyBurned]
            )
        }
    }
}
