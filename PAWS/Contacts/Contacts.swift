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
    let contacts = [
        Contact(
            name: PersonNameComponents(
                givenName: "Scott",
                familyName: "Ceresnak"
            ),
            image: Image("ScottSquarePhoto"), // swiftlint:disable:this accessibility_label_for_image
            title: "Professor of Pediatrics (Cardiology)",
            description: String(localized: "SCOTT_CERESNAK_BIO"),
            organization: "Stanford University",
            address: {
                let address = CNMutablePostalAddress()
                address.country = "USA"
                address.state = "CA"
                address.postalCode = "94304"
                address.city = "Palo Alto"
                address.street = "725 Welch Rd"
                return address
            }(),
            contactOptions: [
                .email(addresses: ["ceresnak@stanford.edu"]),
                ContactOption(
                    image: Image(systemName: "safari.fill"), // swiftlint:disable:this accessibility_label_for_image
                    title: "Website",
                    action: {
                        if let url = URL(string: "https://profiles.stanford.edu/intranet/scott-ceresnak?tab=bio") {
                           UIApplication.shared.open(url)
                        }
                    }
                )
            ]
        ),
        Contact(
            name: PersonNameComponents(
                givenName: "Aydin",
                familyName: "Zahedivash"
            ),
            image: Image("AydinSquarePhoto"), // swiftlint:disable:this accessibility_label_for_image
            title: "Pediatric Stanford Cardiology Fellow",
            description: String(localized: "AYDIN_ZAHEDIVASH_BIO"),
            organization: "Stanford University",
            address: {
                let address = CNMutablePostalAddress()
                address.country = "USA"
                address.state = "CA"
                address.postalCode = "94304"
                address.city = "Palo Alto"
                address.street = "725 Welch Rd"
                return address
            }(),
            contactOptions: [
                .email(addresses: ["aydinz@stanford.edu"]),
                ContactOption(
                    image: Image(systemName: "safari.fill"), // swiftlint:disable:this accessibility_label_for_image
                    title: "Website",
                    action: {
                        if let url = URL(string: "https://profiles.stanford.edu/intranet/scott-ceresnak?tab=bio") {
                           UIApplication.shared.open(url)
                        }
                    }
                )
            ]
        )
    ]
    
    @Binding var presentingAccount: Bool
    
    
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
