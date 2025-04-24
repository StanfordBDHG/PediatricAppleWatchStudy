//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziHealthKit


extension HKElectrocardiogram {
    fileprivate var oneDayPredicate: NSPredicate {
        HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -1, to: self.startDate), // 24 hours before recording.
            end: self.startDate,
            options: .strictStartDate
        )
    }
    
    fileprivate var fiveMinutePredicate: NSPredicate {
        HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .minute, value: -5, to: self.startDate), // 5 minutes before recording.
            end: self.startDate,
            options: .strictStartDate
        )
    }
}


extension HealthKit {
    func supplementalMetrics(for electrocardiogram: HKElectrocardiogram) async throws -> [HKSample] {
        var collectedSupplementalMetrics: [HKSample] = []
        collectedSupplementalMetrics.append(
            contentsOf: try await supplementalMetrics(for: electrocardiogram, ofType: .heartRate)
        )
        collectedSupplementalMetrics.append(
            contentsOf: try await supplementalMetrics(
                for: electrocardiogram,
                ofType: .vo2Max,
                sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
                limit: 1
            )
        )
        collectedSupplementalMetrics.append(
            contentsOf: try await supplementalMetrics(for: electrocardiogram, ofType: .physicalEffort)
        )
        collectedSupplementalMetrics.append(
            contentsOf: try await supplementalMetrics(for: electrocardiogram, ofType: .stepCount)
        )
        collectedSupplementalMetrics.append(
            contentsOf: try await supplementalMetrics(for: electrocardiogram, ofType: .activeEnergyBurned)
        )
        return collectedSupplementalMetrics
    }
    
    
    private func supplementalMetrics<Sample>(
        for electrocardiogram: HKElectrocardiogram,
        ofType type: SampleType<Sample>,
        sortDescriptors: [SortDescriptor<Sample>] = [SortDescriptor(\.startDate)],
        limit: Int? = nil
    ) async throws -> [Sample] {
        // If something is available in last 5 minutes since recording, return those samples.
        guard let fiveMinutesBefore = Calendar.current.date(byAdding: .minute, value: -5, to: electrocardiogram.startDate) else {
            return []
        }
        
        let fiveMinutesBeforeSamples = try await query(
            type,
            timeRange: .since(fiveMinutesBefore),
            limit: limit,
            sortedBy: sortDescriptors
        )
        
        guard fiveMinutesBeforeSamples.isEmpty else {
            return fiveMinutesBeforeSamples
        }
        
        // Otherwise, request the last 24 hours of samples.
        guard let oneDayBefore = Calendar.current.date(byAdding: .day, value: -1, to: electrocardiogram.startDate) else {
            return []
        }
        
        return try await query(
            type,
            timeRange: .since(oneDayBefore),
            limit: limit,
            sortedBy: sortDescriptors
        )
    }
}
