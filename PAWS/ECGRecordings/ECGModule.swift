//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseFirestore
import HealthKit
import HealthKitOnFHIR
import OSLog
import Spezi
import SpeziAccount
import SpeziFirebaseConfiguration
import SpeziHealthKit
import SpeziLocalStorage
import SwiftUI
import UserNotifications


@Observable
class ECGModule: Module, DefaultInitializable, EnvironmentAccessible {
    @ObservationIgnored @Dependency(Account.self) private var account: Account?
    @ObservationIgnored @Dependency(AccountNotifications.self) private var accountNotifications: AccountNotifications?
    @ObservationIgnored @Dependency(HealthKit.self) private var healthKit
    @ObservationIgnored @AppStorage(StorageKeys.healthKitStartDate) var healthKitStartDate: Date?
    
    
    @MainActor private(set) var electrocardiograms: Set<HKElectrocardiogram> = []
    private let healthStore = HKHealthStore()
    private let logger = Logger(subsystem: "PAWS", category: "ECGModule")
    private var notificationsTask: Task<Void, Never>?
    
    
    private var healthKitSamplesEndDateCutoff: Date {
        get async throws {
            // Waiting until Spezi Account loads the account details.
            let loadingStartDate = Date.now
            while await account?.details?.dateOfEnrollment == nil && abs(loadingStartDate.distance(to: .now)) < 0.5 {
                logger.debug("Loading DateOfEnrollment ...")
                try await Task.sleep(for: .seconds(0.02))
            }
            
            // Ensure that the HealthKit start date is set correctly based on the date of enrollment.
            guard let healthKitStartDate = await account?.details?.dateOfEnrollment else {
                logger.error("Not able to load date of enrollment; falling back to the locally stored date of enrollment.")
                
                guard let healthKitStartDate = self.healthKitStartDate else {
                    logger.error("No locally stored date of enrollment. Can not load samples.")
                    throw FirebaseFirestore.Firestore.FirestoreError.userDetailsNotLoading
                }
                
                return healthKitStartDate
            }
            
            self.healthKitStartDate = healthKitStartDate
            return healthKitStartDate
        }
    }
    
    
    nonisolated required init() { }
    
    
    func configure() {
        Task {
            try await self.reloadECGs()
        }
        
        if let accountNotifications {
            notificationsTask = Task.detached { @MainActor [weak self] in
                for await _ in accountNotifications.events {
                    guard let self else {
                        return
                    }
                    
                    Task {
                        try await self.reloadECGs()
                    }
                }
            }
        }
    }
    
    
    func isUploaded(_ electrocardiogram: HKElectrocardiogram, reuploadIfNeeded: Bool = false) async throws -> Bool {
        let documentReference = try await Firestore.firestore().healthKitCollectionReference.document(electrocardiogram.uuid.uuidString)
        let snapshot = try await documentReference.getDocument()
        
        /// This function is intended to re-upload ECGs that have not been completely uploaded. Could be removed in the future.
        func voltageComplete(_ electrocardiogramObservation: FHIRObservation) -> Bool {
            guard let ecgCode = HKElectrocardiogramMapping.default.voltageMeasurements.codings.first else {
                return false
            }
            
            // Unfortunately we have to support compiler with explicity type annotations on slower machines & the CI.
            let voltageMeasurementsComponentsCount = electrocardiogramObservation.component?.filter { component in
                component.code.coding?.contains(where: { coding in
                    coding.code?.value?.string == ecgCode.code && coding.system?.value?.url == ecgCode.system
                }) ?? false
            }.count ?? 0
            
            return voltageMeasurementsComponentsCount >= 3
        }
        
        if snapshot.exists,
           let electrocardiogramObservation = try? snapshot.data(as: FHIRObservation.self),
           voltageComplete(electrocardiogramObservation) {
            return true
        }
        
        if reuploadIfNeeded {
            await upload(electrocardiogram: electrocardiogram)
            logger.log("Uploaded Missing ECG: \(electrocardiogram.id)")
            return true
        }
        
        return false
    }
    
    /// Reloads the ECGs by checking if the user is authenticated.
    /// If the user is authenticated, it sets a sample predicate for the HealthKit query based on the user's account creation date and the current date.
    /// - Throws: An error if the user is not authenticated.
    @MainActor
    func reloadECGs() async throws {
        // Waiting until the HealthKit module loads all authorization requirements.
        let loadingStartDate = Date.now
        while healthKit.configurationState != .completed && abs(loadingStartDate.distance(to: .now)) < 0.5 {
            logger.debug("Loading HealthKit Module ...")
            try await Task.sleep(for: .seconds(0.02))
        }
        
        guard healthKit.isFullyAuthorized else {
            logger.error("HealthKit permissions not yet provided.")
            return
        }
        
        self.electrocardiograms = Set(
            try await healthKit.query(
                .electrocardiogram,
                timeRange: .since(healthKitSamplesEndDateCutoff)
            )
        )
        
        // Somehow HealthKit sometimes returns an empty query at random intervals; we at least give it a second try if it is empty.
        if self.electrocardiograms.isEmpty {
            try? await Task.sleep(for: .seconds(0.5))
            self.electrocardiograms = Set(
                try await healthKit.query(
                    .electrocardiogram,
                    timeRange: .since(healthKitSamplesEndDateCutoff)
                )
            )
        }
        
        guard account?.signedIn ?? false else {
            logger.error("User not authenticated")
            return
        }
        
        await self.uploadUnuploadedECGs()
    }
    
    
    // MARK: - ECG & HealthKit Data Management
    func upload(electrocardiogram: HKElectrocardiogram) async {
        do {
            try await upload(sample: electrocardiogram)
            let supplementalMetrics = try await healthKit.supplementalMetrics(for: electrocardiogram)
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
    
    func updateElectrocardiogram(basedOn categorySample: HKCategorySample) async {
        do {
            guard let updatedElectrocardiogram = try await self.electrocardiogram(
                correlatedWith: categorySample
            ) else {
                return
            }
            
            try await upload(sample: updatedElectrocardiogram, force: true)
        } catch {
            logger.log("Could not corrolate category sample with ECG: \(categorySample)")
        }
    }
    
    @MainActor
    func remove(sample id: HKSample.ID) async throws {
        if let index = electrocardiograms.firstIndex(where: { $0.uuid == id }) {
            electrocardiograms.remove(at: index)
        }
        try await Firestore.firestore().healthKitCollectionReference.document(id.uuidString).delete()
    }
    
    
    // MARK: - Private Helper Functions
    @MainActor
    private func insert(electrocardiogram: HKElectrocardiogram) {
        electrocardiograms.insert(electrocardiogram)
    }
    
    private func electrocardiogram(
        correlatedWith correlatedCategorySample: HKCategorySample
    ) async throws -> HKElectrocardiogram? {
        electrocardiogramLoop: for electrocardiogram in await electrocardiograms {
            guard electrocardiogram.symptomsStatus == .present else {
                continue electrocardiogramLoop
            }
            
            let predicate = HKQuery.predicateForObjectsAssociated(electrocardiogram: electrocardiogram)
            
            for sampleType in HKElectrocardiogram.correlatedSymptomTypes {
                let categorySamples = try await healthKit.query(
                    sampleType,
                    timeRange: .ever,
                    sortedBy: [
                        SortDescriptor(\.endDate, order: .reverse)
                    ],
                    predicate: predicate
                )
                
                sampleLoop: for categorySample in categorySamples {
                    guard categorySample.id == correlatedCategorySample.id else {
                        continue sampleLoop
                    }
                    
                    return electrocardiogram
                }
            }
        }
        
        return nil
    }
    
    
    private func upload(sample: HKSample, force: Bool = false) async throws {
        // We do not upload any samples before the date of enrollment.
        guard try await sample.endDate > healthKitSamplesEndDateCutoff else {
            return
        }
        
        let resource: FHIRResourceProxy
        if let electrocardiogram = sample as? HKElectrocardiogram {
            await self.insert(electrocardiogram: electrocardiogram)
            
            guard try await !self.isUploaded(electrocardiogram) || force else {
                return
            }
            
            async let symptoms = try electrocardiogram.symptoms(from: healthKit)
            async let voltageMeasurements = try electrocardiogram.voltageMeasurements(from: healthStore)
            
            resource = FHIRResourceProxy(
                with: try await electrocardiogram.observation(
                    symptoms: symptoms,
                    voltageMeasurements: voltageMeasurements.map { ($0.timeOffset, $0.voltage) }
                )
            )
        } else {
            resource = try sample.resource()
        }
        
        try await Firestore.firestore().healthKitCollectionReference.document(sample.id.uuidString).setData(from: resource)
    }
    
    private func uploadUnuploadedECGs() async {
        await withTaskGroup(of: Void.self) { group in
            for ecg in await electrocardiograms {
                group.addTask { [weak self] in
                    do {
                        try await self?.upload(sample: ecg)
                    } catch {
                        self?.logger.log("Could not upload ECG: \(error)")
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
