//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseAuth
import FirebaseFirestore
import HealthKit
import OSLog
import enum ModelsR4.ResourceProxy
import Spezi
import SpeziLocalStorage
import SpeziMockWebService
import UserNotifications


@Observable
class ECGModule: Module, DefaultInitializable, EnvironmentAccessible {
    enum StorageKey {
        static let uploadedElectrocardiograms = "ECGModule.uploadedElectrocardiograms"
    }
    
    
    @ObservationIgnored @Dependency var localStorage: LocalStorage
    @ObservationIgnored @StandardActor var standard: PAWSStandard
    @ObservationIgnored @Dependency var mockWebService: MockWebService?
    
    private(set) var electrocardiograms: [HKElectrocardiogram] = []
    private let healthStore = HKHealthStore()
    private let logger = Logger(subsystem: "PAWS", category: "Standard")
    
    
    /// Creates an instance of a ``MockWebService``.
    required init() { }
    
    
    // MARK: - Public Interface
    
    func isUploaded(_ electrocardiogram: HKElectrocardiogram, reuploadIfNeeded: Bool = false) async throws -> Bool {
        let documentReference = try await electrocardiogramDocumentReference(id: electrocardiogram.uuid)
        let snapshot = try await documentReference.getDocument()

        guard !snapshot.exists else {
            return true
        }
        
        if reuploadIfNeeded {
            try await documentReference.setData(from: try electrocardiogram.resource)
            return true
        }
        
        return false
    }
    
    /// Reloads the ECGs by checking if the user is authenticated.
    /// If the user is authenticated, it sets a sample predicate for the HealthKit query based on the user's account creation date and the current date.
    /// - Throws: An error if the user is not authenticated.
    func reloadECGs() async throws {
        guard let user = Auth.auth().currentUser else {
            logger.error("User not authenticated")
            return
        }

        let samplePredicate = HKQuery.predicateForSamples(withStart: user.metadata.creationDate, end: .now, options: .strictStartDate)
        let queryDescriptor = HKSampleQueryDescriptor(
            predicates: [HKSamplePredicate<HKElectrocardiogram>.electrocardiogram(samplePredicate)],
            sortDescriptors: []
        )
        let samples = try await queryDescriptor.result(for: healthStore)
        
        self.electrocardiograms = samples
        try await self.uploadUnuploadedECGs()
    }
    
    func updateElectrocardiogram(basedOn categorySample: HKCategorySample) async {
        do {
            guard let updatedElectrocardiogram = try await self.electrocardiogram(
                correlatedWith: categorySample,
                from: healthStore
            ) else {
                return
            }
            
            try await upload(sample: updatedElectrocardiogram, force: true)
        } catch {
            logger.log("Could not corrolate category sample with ECG: \(categorySample)")
        }
    }
    
    // MARK: - Data Management
    
    func insert(electrocardiogram: HKElectrocardiogram) {
        electrocardiograms.removeAll(where: { $0.uuid == electrocardiogram.id })
        electrocardiograms.append(electrocardiogram)
        electrocardiograms.sort(by: { $0.endDate > $1.endDate })
    }
    
    func remove(electrocardiogram id: HKElectrocardiogram.ID) async throws {
        electrocardiograms.removeAll(where: { $0.uuid == id })
        try await electrocardiogramDocumentReference(id: id).delete()
    }
    
    func upload(electrocardiogram: HKElectrocardiogram) async {
        var supplementalMetrics: [HKSample] = []
        
        do {
            try await upload(sample: electrocardiogram)
            
            supplementalMetrics.append(contentsOf: (try? await electrocardiogram.precedingPulseRates) ?? [])
            supplementalMetrics.append(contentsOf: (try? await electrocardiogram.precedingPhysicalEffort) ?? [])
            supplementalMetrics.append(contentsOf: (try? await electrocardiogram.precedingStepCount) ?? [])
            supplementalMetrics.append(contentsOf: (try? await electrocardiogram.precedingActiveEnergy) ?? [])
            
            if let precedingVo2Max = try? await electrocardiogram.precedingVo2Max {
                supplementalMetrics.append(precedingVo2Max)
            }
            
            for supplementalMetric in supplementalMetrics {
                do {
                    try await upload(sample: supplementalMetric)
                } catch {
                    logger.log("Could not upload \(supplementalMetric.sampleType): \(error)")
                    await addECGMessage(for: supplementalMetric, error: error)
                }
            }
        } catch {
            logger.log("Could not access HealthKit sample: \(error)")
            await addECGMessage(for: electrocardiogram, error: error)
        }
    }
    
    // MARK: - Private Helper Functions
    
    private func electrocardiogram(
        correlatedWith correlatedCategorySample: HKCategorySample,
        from healthStore: HKHealthStore
    ) async throws -> HKElectrocardiogram? {
        electrocardiogramLoop: for electrocardiogram in electrocardiograms {
            guard electrocardiogram.symptomsStatus == .present else {
                continue electrocardiogramLoop
            }
            
            let predicate = HKQuery.predicateForObjectsAssociated(electrocardiogram: electrocardiogram)
            
            for sampleType in HKElectrocardiogram.correlatedSymptomTypes {
                let queryDescriptor = HKSampleQueryDescriptor(
                    predicates: [
                        .sample(type: sampleType, predicate: predicate)
                    ],
                    sortDescriptors: [
                        SortDescriptor(\.endDate, order: .reverse)
                    ]
                )
                
                sampleLoop: for sample in try await queryDescriptor.result(for: healthStore) {
                    guard let categorySample = sample as? HKCategorySample, categorySample.id == correlatedCategorySample.id else {
                        continue sampleLoop
                    }
                    
                    return electrocardiogram
                }
            }
        }
        
        return nil
    }
    
    private func electrocardiogramDocumentReference(id: HKElectrocardiogram.ID) async throws -> DocumentReference {
        try await standard.userDocumentReference
            .collection("HealthKit")
            .document(id.uuidString)
    }
    
    private func upload(sample: HKSample, force: Bool = false) async throws {
        let resource: ResourceProxy
        if let electrocardiogram = sample as? HKElectrocardiogram {
            self.insert(electrocardiogram: electrocardiogram)
            
            guard try await !self.isUploaded(electrocardiogram) || force else {
                return
            }
            
            async let symptoms = try electrocardiogram.symptoms(from: healthStore)
            async let voltageMeasurements = try electrocardiogram.voltageMeasurements(from: healthStore)
            
            resource = ResourceProxy(
                with: try await electrocardiogram.observation(
                    symptoms: symptoms,
                    voltageMeasurements: voltageMeasurements
                )
            )
        } else {
            resource = try sample.resource
        }
        
        if let mockWebService {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let jsonRepresentation = (try? String(data: encoder.encode(resource), encoding: .utf8)) ?? ""
            try await mockWebService.upload(path: "healthkit/\(sample.uuid.uuidString)", body: jsonRepresentation)
        } else {
            try await standard.healthKitDocument(id: sample.id).setData(from: resource)
        }
    }
    
    private func uploadUnuploadedECGs() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for ecg in electrocardiograms where try await !isUploaded(ecg) {
                group.addTask { [weak self] in
                    do {
                        try await self?.upload(sample: ecg)
                    } catch {
                        self?.logger.log("Could not access HealthKit sample: \(error)")
                        await self?.addECGMessage(for: ecg, error: error)
                    }
                }
            }
        }
    }
    
    /// Creates a notification with a title and body message when there is an error accessing a HealthKit sample.
    /// - Parameter sample: The `HKSample` object for which the error occurred.
    private func addECGMessage(for sample: HKSample, error: Error) async {
        let date = sample.startDate
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: date)

        let content = UNMutableNotificationContent()
        content.title = "HealthKit Error"
        content.body = "\(sample.sampleType) recorded on \(dateString) could not be uploaded. Please open the PAWS app to re-upload the sample. \n\n \(error.localizedDescription)"

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
