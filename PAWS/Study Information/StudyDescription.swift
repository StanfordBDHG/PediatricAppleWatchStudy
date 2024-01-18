//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI

struct StudyDescription: View {
    var body: some View {
        PAWSCard {
            VStack(alignment: .leading) {
                HStack {
                    Text("STUDY_DESCRIPTION")
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
                .padding()
                .frame(maxWidth: .infinity)
        }
            .padding(.vertical, 8)
    }
}


#Preview {
    NavigationStack {
        StudyDescription()
    }
}
