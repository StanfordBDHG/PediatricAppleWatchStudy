//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import HealthKit
import SwiftUI


struct ECGRecording: View {
    let hkElectrocardiogram: HKElectrocardiogram
    @State var symptoms: HKElectrocardiogram.Symptoms = [:]
    
    
    var body: some View {
        PAWSCard {
            HStack {
                Text("EEG Recording")
                    .font(.title)
                Text(hkElectrocardiogram.endDate.formatted())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Divider()
                if symptoms.isEmpty {
                    Text("Recorded no symptoms")
                } else {
                    Text("Recorded \(symptoms.count) symptoms.")
                }
            }
        }
        .task {
            guard let symptoms = try? await hkElectrocardiogram.symptoms(from: HKHealthStore()) else {
                return
            }
            
            self.symptoms = symptoms
        }
    }
}

extension HKElectrocardiogram {
    private var fiveMinutesBefore: Date? {
        Calendar.current.date(byAdding: .minute, value: -5, to: self.startDate)
    }
    
    private var fiveMinutePredicate: NSPredicate {
        HKQuery.predicateForSamples(withStart: self.fiveMinutesBefore, end: self.startDate, options: .strictStartDate)
    }
    
    var precedingPulseRates: [HKSample] {
        get async throws {
            try await precedingSamples(forType: HKQuantityType(.heartRate))
        }
    }
    
    var precedingVo2Max: HKSample? {
        get async {
            try? await precedingSamples(forType: HKQuantityType(.vo2Max), limit: 1, ascending: false).first
        }
    }

    var precedingPhysicalEffort: HKQuantity? {
        get async {
            try? await fiveMinuteSum(forType: HKQuantityType(.physicalEffort))
        }
    }
    
    var precedingStepCount: HKQuantity? {
        get async {
            try? await fiveMinuteSum(forType: HKQuantityType(.stepCount))
        }
    }
    
    var precedingActiveEnergy: HKQuantity? {
        get async {
            try? await fiveMinuteSum(forType: HKQuantityType(.activeEnergyBurned))
        }
    }
    
    /// To actually get the heart rate (BPM) from one of the samples:
    /// ```
    /// let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
    /// ```
    func precedingSamples(
        forType type: HKSampleType,
        limit: Int? = nil,
        ascending: Bool = true
    ) async throws -> [HKSample] {
        let healthStore = HKHealthStore()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
        let queryLimit = limit ?? HKObjectQueryNoLimit
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: self.fiveMinutePredicate,
                limit: queryLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples ?? [])
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fiveMinuteSum(forType type: HKQuantityType) async throws -> HKQuantity? {
        let healthStore = HKHealthStore()
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: self.fiveMinutePredicate
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: statistics?.sumQuantity())
                }
            }
            
            healthStore.execute(query)
        }
    }
}
