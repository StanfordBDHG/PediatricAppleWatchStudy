//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct StudyInformation: View {
    @Binding var presentingAccount: Bool
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    StudyDescription()
                    FAQ()
                }
                    .padding(.vertical)
            }
                .toolbar {
                    if AccountButton.shouldDisplay {
                        AccountButton(isPresented: $presentingAccount)
                    }
                }
                .navigationTitle(String(localized: "Study Information"))
        }
    }
    
    
    init(presentingAccount: Binding<Bool>) {
        self._presentingAccount = presentingAccount
    }
}

#Preview {
    StudyInformation(presentingAccount: .constant(false))
}
