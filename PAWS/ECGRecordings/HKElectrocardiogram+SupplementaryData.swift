//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import HealthKit


extension HKElectrocardiogram {
    private var oneDayPredicate: NSPredicate {
        HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -1, to: self.startDate), // 24 hours before recording.
            end: self.startDate,
            options: .strictStartDate
        )
    }
    
    private var fiveMinutePredicate: NSPredicate {
        HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .minute, value: -5, to: self.startDate), // 5 minutes before recording.
            end: self.startDate,
            options: .strictStartDate
        )
    }
    
    var precedingPulseRates: [HKQuantitySample] {
        get async throws {
            try await precedingSamples(forType: HKQuantityType(.heartRate))
        }
    }
    
    var precedingVo2Max: HKQuantitySample? {
        get async throws {
            try await precedingSamples(
                forType: HKQuantityType(.vo2Max),
                sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
                limit: 1
            )
            .first
        }
    }

    var precedingPhysicalEffort: [HKQuantitySample] {
        get async throws {
            try await precedingSamples(forType: HKQuantityType(.physicalEffort))
        }
    }
    
    var precedingStepCount: [HKQuantitySample] {
        get async throws {
            try await precedingSamples(forType: HKQuantityType(.stepCount))
        }
    }
    
    var precedingActiveEnergy: [HKQuantitySample] {
        get async throws {
            try await precedingSamples(forType: HKQuantityType(.activeEnergyBurned))
        }
    }

    
    private func precedingSamples(
        forType type: HKQuantityType,
        sortDescriptors: [SortDescriptor<HKQuantitySample>] = [SortDescriptor(\.startDate)],
        limit: Int? = nil
    ) async throws -> [HKQuantitySample] {
        let store = HKHealthStore()
        let queryDescriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type, predicate: self.fiveMinutePredicate)],
            sortDescriptors: sortDescriptors,
            limit: limit
        )
        
        // If something is available in last 5 minutes since recording, return those samples.
        if let result = try? await queryDescriptor.result(for: store), !result.isEmpty {
            return result
        }
        
        // Otherwise, request the last 24 hours of samples.
        let extendedQueryDescriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type, predicate: self.oneDayPredicate)],
            sortDescriptors: sortDescriptors,
            limit: limit
        )
        
        return try await extendedQueryDescriptor.result(for: store)
    }
}
