//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import HealthKitOnFHIR
import OSLog
import PDFKit
import Spezi
import SpeziAccount
import SpeziFirebaseConfiguration
import SpeziFirestore
import SpeziHealthKit
import SpeziOnboarding
import SwiftUI


actor PAWSStandard: Standard, EnvironmentAccessible, HealthKitConstraint, ConsentConstraint, AccountNotifyConstraint {
    // periphery:ignore - The ConfigureFirebaseApp injection is required to enforce an initialization within Spezi before this module.
    @Dependency(ConfigureFirebaseApp.self) private var firebaseConfiguration
    // periphery:ignore - Uses @AppStorage
    @AppStorage(StorageKeys.healthKitStartDate) var healthKitStartDate: Date?
    @Dependency(ECGModule.self) private var ecgStorage

    private let logger = Logger(subsystem: "PAWS", category: "Standard")
    
    
    private var userBucketReference: StorageReference {
        get async throws {
            guard let accountId = Auth.auth().currentUser?.uid else {
                throw Firestore.FirestoreError.userNotAuthenticatedYet
            }

            return Storage.storage().reference().child("users/\(accountId)")
        }
    }
    
    
    // MARK: - HealthKitConstraint
    func handleNewSamples<Sample>(
        _ addedSamples: some Collection<Sample>,
        ofType sampleType: SampleType<Sample>
    ) async {
        for sample in addedSamples {
            if let electrocardiogram = sample as? HKElectrocardiogram {
                await ecgStorage.upload(electrocardiogram: electrocardiogram)
            } else if let categorySample = sample as? HKCategorySample {
                await ecgStorage.updateElectrocardiogram(basedOn: categorySample)
            } else {
                logger.log("Request to upload unidentified HealthKit Sample: \(sample)")
            }
        }
    }
    
    func handleDeletedObjects<Sample>(
        _ deletedObjects: some Collection<HKDeletedObject>,
        ofType sampleType: SampleType<Sample>
    ) async {
        for sample in deletedObjects {
            do {
                try await ecgStorage.remove(sample: sample.uuid)
            } catch {
                logger.error("Could not remove HealthKit sample: \(error)")
            }
        }
    }
    

    // MARK: - AccountNotifyConstraint
    func respondToEvent(_ event: AccountNotifications.Event) async {
        switch event {
        case .deletingAccount:
            do {
                healthKitStartDate = nil
                // delete all user associated data
                try await Firestore.firestore().userDocumentReference.delete()
            } catch {
                logger.error("Could not delete user document: \(error)")
            }
        case .disassociatingAccount:
            healthKitStartDate = nil
        default:
            break
        }
    }
    
    
    // MARK: - OnboardingConstraint
    /// Stores the given consent form in the user's document directory with a unique timestamped filename.
    ///
    /// - Parameter consent: The consent form's data to be stored as a `PDFDocument`.
    func store(consent: SpeziOnboarding.ConsentDocumentExport) async throws {
        guard !FeatureFlags.disableFirebase else {
            guard let basePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                logger.error("Could not create path for writing consent form to user document directory.")
                return
            }
            
            let filePath = basePath.appending(path: "consent.pdf")
            await consent.pdf.write(to: filePath)
            
            return
        }
        
        guard let consentData = await consent.pdf.dataRepresentation() else {
            logger.error("Could not store consent form.")
            return
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        _ = try await userBucketReference.child("consent.pdf").putDataAsync(consentData, metadata: metadata)
    }
}
