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
