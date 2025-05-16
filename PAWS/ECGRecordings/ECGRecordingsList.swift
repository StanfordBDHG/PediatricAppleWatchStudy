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
        GeometryReader { geometry in
            NavigationStack {
                ScrollView {
                    if ecgModule.electrocardiograms.isEmpty {
                        ContentUnavailableView {
                            Label("No Recordings", systemImage: "waveform.path.ecg")
                        } description: {
                            Text("New ECG Recordings will be displayed here.")
                        }
                            .frame(minHeight: geometry.size.height - 100)
                    }
                    VStack(spacing: 16) {
                        ForEach(ecgModule.electrocardiograms.sorted(by: { $0.endDate > $1.endDate })) { electrocardiogram in
                            ECGRecording(electrocardiogram: electrocardiogram)
                        }
                    }
                        .padding(.vertical)
                }
                    .scrollBounceBehavior(.always)
                    .toolbar {
                        if AccountButton.shouldDisplay {
                            AccountButton(isPresented: $presentingAccount)
                        }
                    }
                    .navigationTitle(String(localized: "ECG Recordings"))
                    .refreshable {
                        try? await ecgModule.reloadECGs()
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
