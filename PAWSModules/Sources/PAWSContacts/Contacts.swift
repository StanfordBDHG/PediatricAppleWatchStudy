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
struct DescriptionView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Study Description")
                .font(.custom("Avenir Next Medium", fixedSize: 36))
            Text("Stanford Sophomore")
                .font(.custom("Avenir Next Medium Italic", fixedSize: 20))
            Text(description)
                .font(.custom("Avenir Next Medium", fixedSize: 15))
                .padding()
        }
    }
    
    
    private var description: String {
        guard let descriptionPath = Bundle.module.path(forResource: "AnanyaVasireddyBio", ofType: "md"),
              let description = try? String(contentsOfFile: descriptionPath) else {
            return ""
        }
        
        return description
    }
}


public struct Contacts: View {
    let contacts = [
        Contact(
            name: PersonNameComponents(
                givenName: "Scott",
                familyName: "Ceresnak"
            ),
            image: Image(systemName: "person.circle"),
            title: "Professor of Pediatrics (Cardiology)",
            description: String(localized: "SCOTT_CERESNAK_BIO", bundle: .module),
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
            image: Image("Aydin", bundle: .module),
            title: "Pediatric Stanford Cardiology Fellow",
            description: String(localized: "AYDIN_ZAHEDIVASH_BIO", bundle: .module),
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
                        if let url = URL(string: "https://profiles.stanford.edu/intranet/scott-ceresnak?tab=bio") {
                           UIApplication.shared.open(url)
                        }
                    }
                )
            ]
        )
    ]
    
    
    public var body: some View {
            NavigationStack {
                ScrollView(.vertical) {
                    DescriptionView()
                    ForEach(contacts, id: \.name) { contact in
                        ContactView(contact: contact)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(Color(.systemBackground))
                                    .shadow(radius: 5)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                    }
                        .padding(.vertical, 6)
                }
                    .background(Color(.systemGroupedBackground))
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
