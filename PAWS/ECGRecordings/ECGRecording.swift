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
    let electrocardiogram: HKElectrocardiogram
    @State var symptoms: HKElectrocardiogram.Symptoms = [:]
    @Environment(ECGModule.self) var ecgModule
    
    
    var body: some View {
        PAWSCard {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("ECG Recording")
                        .font(.title)
                    HStack {
                        Text(electrocardiogram.endDate.formatted())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if ecgModule.isUploaded(electrocardiogram, reuploadIfNeeded: true) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .accessibilityLabel("Checkmark: ECG has been successfully uploaded")
                        } else {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.horizontal, 1)
                        }
                    }
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
                guard let symptoms = try? await electrocardiogram.symptoms(from: HKHealthStore()) else {
                    return
                }
                
                self.symptoms = symptoms
            }
    }
}
