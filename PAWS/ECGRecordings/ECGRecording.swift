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
            // manually query for active calories
        }
    }
}

extension HKElectrocardiogram {
    var fiveMinutesBefore: Date? {
        Calendar.current.date(byAdding: .minute, value: -5, to: self.startDate)
    }
    
    /// To actually get the heart rate (BPM) from one of the samples:
    /// ```
    /// let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
    /// ```
    var precedingPulseRates: [HKSample] {
        precedingSamples(forType: HKQuantityType(.heartRate))
    }
    
    var precedingVo2Max: HKSample? {
        precedingSamples(forType: HKQuantityType(.vo2Max), limit: 1, ascending: false).first
    }
    
    func precedingSamples(forType type: HKSampleType, limit: Int? = nil, ascending: Bool = true) -> [HKSample] {
        let healthStore = HKHealthStore()
        let predicate = HKQuery.predicateForSamples(withStart: fiveMinutesBefore, end: self.startDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
        var quantitySamples: [HKSample] = []
        let queryLimit = limit ?? HKObjectQueryNoLimit
        
        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: queryLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if error == nil, let samples {
                quantitySamples.append(contentsOf: samples)
            }
        }
        
        healthStore.execute(query)
                
        return quantitySamples
    }
}
