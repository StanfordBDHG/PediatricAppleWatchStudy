//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import HealthKit
import Spezi
import SpeziFHIR


@Observable
class ECGModule: Module, DefaultInitializable, EnvironmentAccessible {
    private(set) var electrocardiograms: [FHIRResource] = []
    
    
    /// Creates an instance of a ``MockWebService``.
    required init() { }
    
    
    func contains(electrocardiogram: HKElectrocardiogram) -> Bool {
        electrocardiograms.contains(where: { $0.id == electrocardiogram.uuid.uuidString })
    }
    
    @discardableResult
    func insert(electrocardiogram: HKElectrocardiogram) async throws -> FHIRResource {
        let healthStore = HKHealthStore()
        async let symptoms = try electrocardiogram.symptoms(from: healthStore)
        async let voltageMeasurements = try electrocardiogram.voltageMeasurements(from: healthStore)
        
        let resource = FHIRResource(
            resource: try await electrocardiogram.observation(
                symptoms: symptoms,
                voltageMeasurements: voltageMeasurements
            ),
            displayName: ""
        )
        
        remove(electrocardiogram: electrocardiogram.uuid)
        electrocardiograms.append(resource)
        electrocardiograms.sort(by: { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) })
        
        return resource
    }
    
    func remove(electrocardiogram id: HKElectrocardiogram.ID) {
        electrocardiograms.removeAll(where: { $0.id == id.uuidString })
    }
    
    func electrocardiogram(
        correlatedWith correlatedCategorySample: HKCategorySample,
        from healthStore: HKHealthStore
    ) async throws -> HKElectrocardiogram? {
        fatalError()
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
