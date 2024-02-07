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

    var precedingPhysicalEffort: HKQuantity? {
        fiveMinuteSum(forType: HKQuantityType(.physicalEffort))
    }
    
    var precedingStepCount: HKQuantity? {
        fiveMinuteSum(forType: HKQuantityType(.stepCount))
    }
    
    var precedingActiveEnergy: HKQuantity? {
        fiveMinuteSum(forType: HKQuantityType(.activeEnergyBurned))
    }
    
    private func precedingSamples(forType type: HKSampleType, limit: Int? = nil, ascending: Bool = true) -> [HKSample] {
        let healthStore = HKHealthStore()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: ascending)
        let queryLimit = limit ?? HKObjectQueryNoLimit
        var result: [HKSample] = []
        
        let query = HKSampleQuery(
            sampleType: type,
            predicate: self.fiveMinutePredicate,
            limit: queryLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if error == nil, let samples {
                result.append(contentsOf: samples)
            }
        }
        
        healthStore.execute(query)
                
        return result
    }
    
    private func fiveMinuteSum(forType type: HKQuantityType) -> HKQuantity? {
        let healthStore = HKHealthStore()
        var result: HKQuantity?
        
        let query = HKStatisticsQuery(
            quantityType: type,
            quantitySamplePredicate: self.fiveMinutePredicate
        ) { _, statistics, error in
            if error != nil {
                result = statistics?.sumQuantity()
            }
        }
        
        healthStore.execute(query)
        
        return result
    }
}
