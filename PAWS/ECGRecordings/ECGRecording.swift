//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import HealthKit
import SpeziFHIR
import SwiftUI


struct ECGRecording: View {
    let electrocardiogram: FHIRResource
    @State var symptoms: HKElectrocardiogram.Symptoms = [:]
    
    
    var body: some View {
        PAWSCard {
            VStack(alignment: .leading) {
                Text("EEG Recording")
                    .font(.title)
                if let date = electrocardiogram.date {
                    Text(date.formatted())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Divider()
                if symptoms.isEmpty {
                    Text("Recorded no symptoms")
                } else {
                    Text("Recorded \(symptoms.count) symptoms.")
                }
            }
                .padding()
        }
            .task {
                #warning("Implement ...")
//                guard let symptoms = try? await electrocardiogram.symptoms(from: HKHealthStore()) else {
//                    return
//                }
                
                self.symptoms = symptoms
            }
    }
}
