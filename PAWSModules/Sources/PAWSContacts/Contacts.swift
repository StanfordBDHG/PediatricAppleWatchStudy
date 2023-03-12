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

struct Question1234View: View {
    var body: some View {
        VStack(spacing: 1) {
            Text("FAQ")
                .font(.custom("Gill Sans", fixedSize: 28))
        }
        VStack(spacing: 1) {
            Text("1. After pressing the event button on the Zio Patch, what do I do if I don’t get a successful recording on my Apple Watch?")
                .font(.custom("Gill Sans SemiBold", fixedSize: 19))
                .padding()
            Text(question1)
                .font(.custom("GillSans", fixedSize: 18))
                .padding()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color(.systemBackground))
                .frame(width: 360)
                .shadow(radius: 5)
                .opacity(0.9)
                .border(LinearGradient(
                    colors: [.red, .pink, .yellow],
                    startPoint: .leading,
                    endPoint: .trailing
                ), width: 5)
                .cornerRadius(10)
                .shadow(radius: 10)
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
        
        VStack(spacing: 1) {
            Text("2. What happens if I don’t have internet access when I record the Apple Watch ECG?")
                .font(.custom("Gill Sans SemiBold", fixedSize: 19))
                .padding()
            Text(question2)
                .font(.custom("GillSans", fixedSize: 18))
                .padding()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color(.systemBackground))
                .frame(width: 360)
                .shadow(radius: 5)
                .opacity(0.9)
                .border(LinearGradient(
                    colors: [.red, .pink, .yellow],
                    startPoint: .leading,
                    endPoint: .trailing
                ), width: 5)
                .cornerRadius(10)
                .shadow(radius: 10)
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
        
        VStack(spacing: 1) {
            Text("3. Will the research team use my Apple Watch ECG data to provide care or change my treatment plan?")
                .font(.custom("Gill Sans SemiBold", fixedSize: 19))
                .padding()
            Text(question3)
                .font(.custom("GillSans", fixedSize: 18))
                .padding()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color(.systemBackground))
                .frame(width: 360)
                .shadow(radius: 5)
                .opacity(0.9)
                .border(LinearGradient(
                    colors: [.red, .pink, .yellow],
                    startPoint: .leading,
                    endPoint: .trailing
                ), width: 5)
                .cornerRadius(10)
                .shadow(radius: 10)
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
        
        VStack(spacing: 1) {
            Text("4. If I am experiencing symptoms that need immediate medical attention, will the PAWS app or Apple Watch call 9-1-1 for me?")
                .font(.custom("Gill Sans SemiBold", fixedSize: 19))
                .padding()
            Text(question4)
                .font(.custom("GillSans", fixedSize: 18))
                .padding()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color(.systemBackground))
                .frame(width: 360)
                .shadow(radius: 5)
                .opacity(0.9)
                .border(LinearGradient(
                    colors: [.red, .pink, .yellow],
                    startPoint: .leading,
                    endPoint: .trailing
                ), width: 5)
                .cornerRadius(10)
                .shadow(radius: 10)
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
    
    private var question1: String {
        guard let question1Path = Bundle.module.path(forResource: "Question1", ofType: "md"),
              let question1 = try? String(contentsOfFile: question1Path) else {
            return ""
        }
        
        return question1
    }
    
    private var question2: String {
        guard let question2Path = Bundle.module.path(forResource: "Question2", ofType: "md"),
              let question2 = try? String(contentsOfFile: question2Path) else {
            return ""
        }
        
        return question2
    }
    
    private var question3: String {
        guard let question3Path = Bundle.module.path(forResource: "Question3", ofType: "md"),
              let question3 = try? String(contentsOfFile: question3Path) else {
            return ""
        }
        
        return question3
    }
    
    private var question4: String {
        guard let question4Path = Bundle.module.path(forResource: "Question4", ofType: "md"),
              let question4 = try? String(contentsOfFile: question4Path) else {
            return ""
        }
        
        return question4
    }
}

struct Question56789View: View {
    var body: some View {
        VStack(spacing: 1) {
            Text("5. Can anything bad happen to me by participating in this study?")
                .font(.custom("Gill Sans SemiBold", fixedSize: 19))
                .padding()
            Text(question5)
                .font(.custom("GillSans", fixedSize: 18))
                .padding()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color(.systemBackground))
                .frame(width: 360)
                .shadow(radius: 5)
                .opacity(0.9)
                .border(LinearGradient(
                    colors: [.red, .pink, .yellow],
                    startPoint: .leading,
                    endPoint: .trailing
                ), width: 5)
                .cornerRadius(10)
                .shadow(radius: 10)
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
        
        VStack(spacing: 1) {
            Text("6. Can anything good happen to me by participating in this study?")
                .font(.custom("Gill Sans SemiBold", fixedSize: 19))
                .padding()
            Text(question6)
                .font(.custom("GillSans", fixedSize: 18))
                .padding()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color(.systemBackground))
                .frame(width: 360)
                .shadow(radius: 5)
                .opacity(0.9)
                .border(LinearGradient(
                    colors: [.red, .pink, .yellow],
                    startPoint: .leading,
                    endPoint: .trailing
                ), width: 5)
                .cornerRadius(10)
                .shadow(radius: 10)
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
        
        VStack(spacing: 1) {
            Text("7. Will anyone know I am in the study?")
                .font(.custom("Gill Sans SemiBold", fixedSize: 19))
                .padding()
            Text(question7)
                .font(.custom("GillSans", fixedSize: 18))
                .padding()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color(.systemBackground))
                .frame(width: 360)
                .shadow(radius: 5)
                .opacity(0.9)
                .border(LinearGradient(
                    colors: [.red, .pink, .yellow],
                    startPoint: .leading,
                    endPoint: .trailing
                ), width: 5)
                .cornerRadius(10)
                .shadow(radius: 10)
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
        
        VStack(spacing: 1) {
            Text("8. Who can I talk to about the study?")
                .font(.custom("Gill Sans SemiBold", fixedSize: 19))
                .padding()
            Text(question8)
                .font(.custom("GillSans", fixedSize: 18))
                .padding()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color(.systemBackground))
                .frame(width: 360)
                .shadow(radius: 5)
                .opacity(0.9)
                .border(LinearGradient(
                    colors: [.red, .pink, .yellow],
                    startPoint: .leading,
                    endPoint: .trailing
                ), width: 5)
                .cornerRadius(10)
                .shadow(radius: 10)
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
        
        VStack(spacing: 1) {
            Text("9. What if I do not want to be in the study?")
                .font(.custom("Gill Sans SemiBold", fixedSize: 19))
                .padding()
            Text(question9)
                .font(.custom("GillSans", fixedSize: 18))
                .padding()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color(.systemBackground))
                .frame(width: 360)
                .shadow(radius: 5)
                .opacity(0.9)
                .border(LinearGradient(
                    colors: [.red, .pink, .yellow],
                    startPoint: .leading,
                    endPoint: .trailing
                ), width: 5)
                .cornerRadius(10)
                .shadow(radius: 10)
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
    
    private var question5: String {
        guard let question5Path = Bundle.module.path(forResource: "Question5", ofType: "md"),
              let question5 = try? String(contentsOfFile: question5Path) else {
            return ""
        }
        
        return question5
    }
    
    private var question6: String {
        guard let question6Path = Bundle.module.path(forResource: "Question6", ofType: "md"),
              let question6 = try? String(contentsOfFile: question6Path) else {
            return ""
        }
        
        return question6
    }
    
    private var question7: String {
        guard let question7Path = Bundle.module.path(forResource: "Question7", ofType: "md"),
              let question7 = try? String(contentsOfFile: question7Path) else {
            return ""
        }
        
        return question7
    }
    
    private var question8: String {
        guard let question8Path = Bundle.module.path(forResource: "Question8", ofType: "md"),
              let question8 = try? String(contentsOfFile: question8Path) else {
            return ""
        }
        
        return question8
    }
    
    private var question9: String {
        guard let question9Path = Bundle.module.path(forResource: "Question9", ofType: "md"),
              let question9 = try? String(contentsOfFile: question9Path) else {
            return ""
        }
        
        return question9
    }
}

public struct Contacts: View {
    let contacts = [
        Contact(
            name: PersonNameComponents(
                givenName: "Scott",
                familyName: "Ceresnak"
            ),
            image: Image(decorative: "ScottSquarePhoto"),
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
            image: Image(decorative: "AydinSquarePhoto"),
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
                        .padding(.vertical, 12)
                    Question1234View()
                        .padding(.vertical, 12)
                    Question56789View()
                        .padding(.vertical, 12)
                    Text("CONTACTS")
                        .font(.custom("Gill Sans", fixedSize: 28))
                    ForEach(contacts, id: \.name) { contact in
                        ContactView(contact: contact)
                            .padding()
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(Color(.systemBackground))
                                    .frame(width: 360)
                                    .shadow(radius: 5)
                                    .opacity(0.9)
                                    .border(LinearGradient(
                                        colors: [.red, .pink, .yellow],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ), width: 5)
                                    .cornerRadius(10)
                                    .shadow(radius: 10)
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
