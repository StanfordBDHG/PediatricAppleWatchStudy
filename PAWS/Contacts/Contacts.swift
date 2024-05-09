//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziContact
import SwiftUI


/// Displays the contacts for the PAWS.
struct Contacts: View {
    @Environment(EnrollmentGroup.self) private var enrollmentGroup
    @Binding var presentingAccount: Bool
    
    
    private var contacts: [Contact] {
        switch enrollmentGroup.studyType {
        case .adult:
            [.scott, .aydin, .brynn]
        case .pediatric:
            [.scott, .aydin]
        case .none:
            []
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(contacts, id: \.name) { contact in
                        PAWSCard {
                            ContactView(contact: contact)
                                .buttonStyle(.plain) // ensure the whole list row doesn't render as a button
                                .padding()
                        }
                    }
                }
                    .padding(.vertical)
            }
                .navigationTitle(String(localized: "CONTACTS_NAVIGATION_TITLE"))
                .toolbar {
                    if AccountButton.shouldDisplay {
                        AccountButton(isPresented: $presentingAccount)
                    }
                }
        }
    }
    
    
    init(presentingAccount: Binding<Bool>) {
        self._presentingAccount = presentingAccount
    }
}


#if DEBUG
#Preview {
    Contacts(presentingAccount: .constant(false))
}
#endif
