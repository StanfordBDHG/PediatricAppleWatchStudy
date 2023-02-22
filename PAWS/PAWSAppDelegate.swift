//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import CardinalKit
import FHIR
import FHIRToFirestoreAdapter
import FirebaseAccount
import FirestoreDataStorage
import FirestoreStoragePrefixUserIdAdapter
import HealthKit
import HealthKitDataSource
import HealthKitToFHIRAdapter
import PAWSMockDataStorageProvider
import Questionnaires
import Scheduler
import SwiftUI


class PAWSAppDelegate: CardinalKitAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: FHIR()) {
            if !CommandLine.arguments.contains("--disableFirebase") {
                FirebaseAccountConfiguration(emulatorSettings: (host: "localhost", port: 9099))
                firestore
            }
            if HKHealthStore.isHealthDataAvailable() {
                healthKit
            }
            QuestionnaireDataSource()
            MockDataStorageProvider()
        }
    }
    
    
    private var firestore: Firestore<FHIR> {
        Firestore(
            adapter: {
                FHIRToFirestoreAdapter()
                FirestoreStoragePrefixUserIdAdapter()
            },
            settings: .emulator
        )
    }
    
    
    private var healthKit: HealthKit<FHIR> {
        HealthKit {
            CollectSample(
                HKQuantityType(.heartRate),
                deliverySetting: .anchorQuery(.afterAuthorizationAndApplicationWillLaunch)
            )
            CollectSample(
                HKQuantityType(.heartRateVariabilitySDNN),
                deliverySetting: .anchorQuery(.afterAuthorizationAndApplicationWillLaunch)
            )
            CollectSample(
                HKQuantityType(.restingHeartRate),
                deliverySetting: .anchorQuery(.afterAuthorizationAndApplicationWillLaunch)
            )
            CollectSample(
                HKQuantityType.electrocardiogramType(),
                deliverySetting: .anchorQuery(.afterAuthorizationAndApplicationWillLaunch)
            )
        } adapter: {
            HealthKitToFHIRAdapter()
        }
    }
}
