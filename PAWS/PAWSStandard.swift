//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseFirestore
import FirebaseStorage
import HealthKitOnFHIR
import OSLog
import PDFKit
import Spezi
import SpeziAccount
import SpeziFirebaseAccountStorage
import SpeziFirestore
import SpeziHealthKit
import SpeziMockWebService
import SpeziOnboarding
import SwiftUI


actor PAWSStandard: Standard, EnvironmentAccessible, HealthKitConstraint, OnboardingConstraint, AccountStorageConstraint {
    enum PAWSStandardError: Error {
        case userNotAuthenticatedYet
    }

    private static var userCollection: CollectionReference {
        Firestore.firestore().collection("users")
    }

    @Dependency var mockWebService: MockWebService?
    @Dependency var accountStorage: FirestoreAccountStorage?
    @Dependency var ecgStorage: ECGModule

    @AccountReference var account: Account

    private let logger = Logger(subsystem: "PAWS", category: "Standard")
    
    
    private var userDocumentReference: DocumentReference {
        get async throws {
            guard let details = await account.details else {
                throw PAWSStandardError.userNotAuthenticatedYet
            }

            return Self.userCollection.document(details.accountId)
        }
    }
    
    private var userBucketReference: StorageReference {
        get async throws {
            guard let details = await account.details else {
                throw PAWSStandardError.userNotAuthenticatedYet
            }

            return Storage.storage().reference().child("users/\(details.accountId)")
        }
    }


    init() {
        if !FeatureFlags.disableFirebase {
            _accountStorage = Dependency(wrappedValue: FirestoreAccountStorage(storeIn: PAWSStandard.userCollection))
        }
    }


    func add(sample: HKSample) async {
        var precedingPulseRates: [HKSample] = []
        var precedingVo2Max: HKSample?
        var precedingPhysicalEffort: HKQuantity?
        var precedingStepCount: HKQuantity?
        var precedingActiveEnergy: HKQuantity?
        
        if let hkElectrocardiogram = sample as? HKElectrocardiogram {
            ecgStorage.hkElectrocardiograms.append(hkElectrocardiogram)
            if let pulseRates = try? await hkElectrocardiogram.precedingPulseRates {
                precedingPulseRates.append(contentsOf: pulseRates)
            }
            precedingPhysicalEffort = await hkElectrocardiogram.precedingPhysicalEffort
            precedingStepCount = await hkElectrocardiogram.precedingStepCount
            precedingActiveEnergy = await hkElectrocardiogram.precedingActiveEnergy
            precedingVo2Max = await hkElectrocardiogram.precedingVo2Max
        }
        
        if let mockWebService {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let jsonRepresentation = (try? String(data: encoder.encode(sample.resource), encoding: .utf8)) ?? ""
            try? await mockWebService.upload(path: "healthkit/\(sample.uuid.uuidString)", body: jsonRepresentation)
            guard let hkElectrocardiogram = sample as? HKElectrocardiogram else {
                return
            }
            
            // Upload supplemental metrics.
            let supplementalPath = "healthkit/\(sample.uuid.uuidString)/supplemental"
            try? await mockWebService.upload(path: "\(supplementalPath)/precedingPulseRates", body: String(data: encoder.encode(precedingPulseRates.compactMap { try? $0.resource }), encoding: .utf8) ?? "")
            let precedingVo2MaxRepresentation = (try? String(data: encoder.encode(precedingVo2Max?.resource), encoding: .utf8)) ?? ""
            try? await mockWebService.upload(path: "\(supplementalPath)/precedingVo2Max", body: precedingVo2MaxRepresentation)
            let wattsPerSquareMeter: HKUnit = .watt().unitDivided(by: .meter().unitRaised(toPower: 2))
            let precedingPhysicalEffortRepresentation = (try? String(
                data: encoder.encode(precedingPhysicalEffort?.doubleValue(for: wattsPerSquareMeter)),
                encoding: .utf8
            )) ?? ""
            try? await mockWebService.upload(path: "\(supplementalPath)/precedingPhysicalEffort", body: precedingPhysicalEffortRepresentation)
            let precedingStepCountRepresentation =
            (try? String(data: encoder.encode(precedingStepCount?.doubleValue(for: .count())), encoding: .utf8)) ?? ""
            try? await mockWebService.upload(path: "\(supplementalPath)/precedingStepCount", body: precedingStepCountRepresentation)
            let precedingActiveEnergyRepresentation =
            (try? String(data: encoder.encode(precedingActiveEnergy?.doubleValue(for: .smallCalorie())), encoding: .utf8)) ?? ""
            try? await mockWebService.upload(path: "\(supplementalPath)/precedingActiveEnergy", body: precedingActiveEnergyRepresentation)
            
            return
        }
        
        do {
            try await healthKitDocument(id: sample.id).setData(from: sample.resource)
            let supplementalMetrics: [String: Any] = [
                "precedingPulseRates": precedingPulseRates
            ]
            try await healthKitDocument(id: sample.id).setData(supplementalMetrics, merge: true)
        } catch {
            logger.error("Could not store HealthKit sample: \(error)")
        }
    }
    
    func remove(sample: HKDeletedObject) async {
        ecgStorage.hkElectrocardiograms.removeAll(where: { $0.id == sample.uuid })
        
        if let mockWebService {
            try? await mockWebService.remove(path: "healthkit/\(sample.uuid.uuidString)")
            return
        }
        
        do {
            try await healthKitDocument(id: sample.uuid).delete()
        } catch {
            logger.error("Could not remove HealthKit sample: \(error)")
        }
    }
    
    
    private func healthKitDocument(id uuid: UUID) async throws -> DocumentReference {
        try await userDocumentReference
            .collection("HealthKit") // Add all HealthKit sources in a /HealthKit collection.
            .document(uuid.uuidString) // Set the document identifier to the UUID of the document.
    }

    func deletedAccount() async throws {
        // delete all user associated data
        do {
            try await userDocumentReference.delete()
        } catch {
            logger.error("Could not delete user document: \(error)")
        }
    }
    
    /// Stores the given consent form in the user's document directory with a unique timestamped filename.
    ///
    /// - Parameter consent: The consent form's data to be stored as a `PDFDocument`.
    func store(consent: PDFDocument) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = formatter.string(from: Date())
        
        guard !FeatureFlags.disableFirebase else {
            guard let basePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                logger.error("Could not create path for writing consent form to user document directory.")
                return
            }
            
            let filePath = basePath.appending(path: "consentForm_\(dateString).pdf")
            consent.write(to: filePath)
            
            return
        }
        
        do {
            guard let consentData = consent.dataRepresentation() else {
                logger.error("Could not store consent form.")
                return
            }
            
            let metadata = StorageMetadata()
            metadata.contentType = "application/pdf"
            _ = try await userBucketReference.child("consent/\(dateString).pdf").putDataAsync(consentData, metadata: metadata)
        } catch {
            logger.error("Could not store consent form: \(error)")
        }
    }


    func create(_ identifier: AdditionalRecordId, _ details: SignupDetails) async throws {
        guard let accountStorage else {
            preconditionFailure("Account Storage was requested although not enabled in current configuration.")
        }
        try await accountStorage.create(identifier, details)
    }

    func load(_ identifier: AdditionalRecordId, _ keys: [any AccountKey.Type]) async throws -> PartialAccountDetails {
        guard let accountStorage else {
            preconditionFailure("Account Storage was requested although not enabled in current configuration.")
        }
        return try await accountStorage.load(identifier, keys)
    }

    func modify(_ identifier: AdditionalRecordId, _ modifications: AccountModifications) async throws {
        guard let accountStorage else {
            preconditionFailure("Account Storage was requested although not enabled in current configuration.")
        }
        try await accountStorage.modify(identifier, modifications)
    }

    func clear(_ identifier: AdditionalRecordId) async {
        guard let accountStorage else {
            preconditionFailure("Account Storage was requested although not enabled in current configuration.")
        }
        await accountStorage.clear(identifier)
    }

    func delete(_ identifier: AdditionalRecordId) async throws {
        guard let accountStorage else {
            preconditionFailure("Account Storage was requested although not enabled in current configuration.")
        }
        try await accountStorage.delete(identifier)
    }
}
