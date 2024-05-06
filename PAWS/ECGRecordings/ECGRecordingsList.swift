//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct ECGRecordingsList: View {
    @Environment(ECGModule.self) var ecgModule
    @Binding var presentingAccount: Bool
    
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    if ecgModule.electrocardiograms.isEmpty {
                        ContentUnavailableView {
                            Label("No Recordings", systemImage: "waveform.path.ecg")
                        } description: {
                            Text("New ECG Recordings will be displayed here.")
                        }
                            .frame(minHeight: geometry.size.height)
                    }
                    VStack(spacing: 16) {
                        ForEach(ecgModule.electrocardiograms) { electrocardiogram in
                            ECGRecording(electrocardiogram: electrocardiogram)
                        }
                    }
                        .padding(.vertical)
                }
                    .scrollBounceBehavior(.basedOnSize)
            }
                .toolbar {
                    if AccountButton.shouldDisplay {
                        AccountButton(isPresented: $presentingAccount)
                    }
                }
                .navigationTitle(String(localized: "ECG Recordings"))
                .refreshable {
                    do {
                        try await ecgModule.reloadECGs()
                    } catch {
                        // logger.error("Error fetching ECG data: \(error.localizedDescription)")
                    }
                }
        }
    }
    
    
    init(presentingAccount: Binding<Bool>) {
        self._presentingAccount = presentingAccount
    }
}


#Preview {
    ECGRecordingsList(presentingAccount: .constant(false))
        .previewWith {
            ECGModule()
        }
}
