//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Contact
import Foundation
import SwiftUI


/// Displays the contacts for the CS342 2023 PAWS Team Application.
public struct Contacts: View {
    let contacts = [
        Contact(
            name: PersonNameComponents(
                givenName: "Scott",
                familyName: "Ceresnak"
            ),
            <<<<<<< danny
            image: Image(systemName: "figure.wave.circle"),
            title: "Professor of Pediatrics (Cardiology)",
            description: String(localized: "SCOTT_CERESNAK_BIO", bundle: .module),
            organization: "Lucile Packard Children's Hospital Stanford",
            =======
            image: Image(systemName: "person.circle"),
            title: "Professor of Pediatrics (Cardiology)",
            description: String(localized: "SCOTT_CERESNAK_BIO", bundle: .module),
            organization: "Stanford University",
            >>>>>>> main
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
            <<<<<<< danny
                //.call("+1 (650) 723-2300"),
                //.text("+1 (650) 723-2300"),
            =======
            >>>>>>> main
                .email(addresses: ["ceresnak@stanford.edu"]),
                ContactOption(
                    image: Image(systemName: "safari.fill"),
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
            <<<<<<< danny
            image: Image(systemName: "figure.wave.circle"),
            title: "Pediatric Stanford Cardiology Fellow",
            description: String(localized: "", bundle: .module),
            organization: "Lucile Packard Children's Hospital Stanford",
             =======
            image: Image(systemName: "person.circle"),
            title: "Pediatric Stanford Cardiology Fellow",
            description: String(localized: "AYDIN_ZAHEDIVASH_BIO", bundle: .module),
            organization: "Stanford University",
            >>>>>>> main
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
            <<<<<<< danny
                //.call("+1 (650) 723-2300"),
                //.text("+1 (650) 723-2300"),
                .email(addresses: ["ceresnak@stanford.edu"]),
            =======
                .email(addresses: ["aydinz@stanford.edu"]),
            >>>>>>> main
                ContactOption(
                    image: Image(systemName: "safari.fill"),
                    title: "Website",
                    action: {
                    <<<<<<< danny
                        if let url = URL(string: "https://dura.stanford.edu/profiles/aydin-zahedivash") {
                    =======
                        if let url = URL(string: "https://profiles.stanford.edu/intranet/scott-ceresnak?tab=bio") {
                    >>>>>>> main
                           UIApplication.shared.open(url)
                        }
                    }
                )
            ]
        )
    ]
    
    
    public var body: some View {
        NavigationStack {
            ContactsList(contacts: contacts)
                .navigationTitle(String(localized: "CONTACTS_NAVIGATION_TITLE", bundle: .module))
        }
    }
    
    
    public init() {}
}


struct Contacts_Previews: PreviewProvider {
    static var previews: some View {
        Contacts()
    }
}
