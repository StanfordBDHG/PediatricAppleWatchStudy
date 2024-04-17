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


extension Contact {
    static let scott = Contact(
        name: PersonNameComponents(
            givenName: "Scott",
            familyName: "Ceresnak"
        ),
        image: Image("ScottSquarePhoto"),
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
                image: Image(systemName: "safari.fill"),
                title: "Website",
                action: {
                    if let url = URL(string: "https://profiles.stanford.edu/scott-ceresnak?tab=bio") {
                        UIApplication.shared.open(url)
                    }
                }
            )
        ]
    )
    static let aydin = Contact(
        name: PersonNameComponents(
            givenName: "Aydin",
            familyName: "Zahedivash"
        ),
        image: Image("AydinSquarePhoto"),
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
                image: Image(systemName: "safari.fill"),
                title: "Website",
                action: {
                    if let url = URL(string: "https://profiles.stanford.edu/aydin-zahedivash?tab=bio") {
                        UIApplication.shared.open(url)
                    }
                }
            )
        ]
    )
    static let brynne = Contact(
        name: PersonNameComponents(
            givenName: "Brynne"
        )
    )
}
