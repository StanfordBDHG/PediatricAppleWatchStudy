//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import HealthKit
import Spezi
import SpeziLocalStorage


@Observable
class ECGModule: Module, DefaultInitializable, EnvironmentAccessible {
    enum StorageKey {
        static let uploadedElectrocardiograms = "ECGModule.uploadedElectrocardiograms"
    }
    
    
    @ObservationIgnored @Dependency var localStorage: LocalStorage
    
    private(set) var electrocardiograms: [HKElectrocardiogram] = []
    private var uploadedElectrocardiograms: Set<HKElectrocardiogram.ID> = []
    
    
    /// Creates an instance of a ``MockWebService``.
    required init() { }
    
    
    func configure() {
        uploadedElectrocardiograms = (try? localStorage.read(storageKey: StorageKey.uploadedElectrocardiograms)) ?? []
    }
    
    
    func isUploaded(_ electrocardiogram: HKElectrocardiogram) -> Bool {
        uploadedElectrocardiograms.contains(where: { $0 == electrocardiogram.uuid })
    }
    
    func markAsUploaded(_ electrocardiogram: HKElectrocardiogram) {
        uploadedElectrocardiograms.insert(electrocardiogram.uuid)
        try? localStorage.store(uploadedElectrocardiograms, storageKey: StorageKey.uploadedElectrocardiograms)
    }
    
    func insert(electrocardiogram: HKElectrocardiogram) {
        electrocardiograms.removeAll(where: { $0.uuid == electrocardiogram.id })
        electrocardiograms.append(electrocardiogram)
        electrocardiograms.sort(by: { $0.endDate > $1.endDate })
    }
    
    func remove(electrocardiogram id: HKElectrocardiogram.ID) {
        electrocardiograms.removeAll(where: { $0.uuid == id })
        uploadedElectrocardiograms.remove(id)
        try? localStorage.store(uploadedElectrocardiograms, storageKey: StorageKey.uploadedElectrocardiograms)
    }
    
    func electrocardiogram(
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
}
