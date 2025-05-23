//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziHealthKit
import SwiftUI


struct ECGRecording: View {
    let electrocardiogram: HKElectrocardiogram
    @State var symptoms: HKElectrocardiogram.Symptoms = [:]
    @State var isUploaded = false
    @Environment(ECGModule.self) var ecgModule
    @Environment(HealthKit.self) var healthKit
    
    
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
                        if isUploaded {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .accessibilityLabel("Checkmark: ECG has been successfully uploaded")
                        } else if !FeatureFlags.disableFirebase {
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
                guard let symptoms = try? await electrocardiogram.symptoms(from: healthKit) else {
                    return
                }
                
                self.symptoms = symptoms
                
                if !FeatureFlags.disableFirebase {
                    self.isUploaded = (try? await ecgModule.isUploaded(electrocardiogram, reuploadIfNeeded: true)) ?? false
                }
            }
    }
}
