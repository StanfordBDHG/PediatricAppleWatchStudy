//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Account
import class FHIR.FHIR
import FirebaseAccount
import Foundation
import SwiftUI
import Views


public struct HomeScreen: View {
    private let backgroundGradient = LinearGradient(
        colors: [.red, .pink, .orange, .yellow],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    @EnvironmentObject var account: Account
    @EnvironmentObject var firebaseAccountConfiguration: FirebaseAccountConfiguration<FHIR>
    @EnvironmentObject var mockDataStorageProvider: MockDataStorageProvider

    
    public var body: some View {
        let name = firebaseAccountConfiguration.user?.displayName ?? "Name Needed"
        
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text("Hello,")
                            .padding([.top], 10)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(firstName(fullName: name).capitalized)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding([.top], 0)
                            .padding([.bottom], 10)
                    }
                    .padding()
                    Image(systemName: "pawprint.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.black)
                        .padding([.top], 20)
                        .padding([.leading], 190)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.top, .leading, .trailing], 10)
                Divider().frame(maxWidth: .infinity)
                recording
                aboutstudy
            }.frame(maxHeight: .infinity, alignment: .top)
        }
    }
    @ViewBuilder var recording: some View {
        if mockDataStorageProvider.mockUploads.isEmpty {
            VStack(spacing: 32) {
                Text("No Recordings Uploaded")
                    .multilineTextAlignment(.center)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(32)
        } else {
            VStack(alignment: .leading) {
                Text("Latest Recording")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding([.top], 10)
                    .padding(.leading, 10)
                    .foregroundColor(.gray)
                let uploadList = mockDataStorageProvider.mockUploads
                let latest = uploadList[0]
                LatestRecording(mockUpload: latest)
            }
            .padding([.top, .leading, .trailing], 10)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
    @ViewBuilder var aboutstudy: some View {
        VStack(alignment: .leading) {
            Text("About The Study")
                .font(.title3)
                .fontWeight(.bold)
                .padding([.top], 10)
                .padding(.leading, 10)
                .foregroundColor(.gray)
            AboutStudy()
        }
        .padding([.top, .leading, .trailing], 10)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    
    public init() {}

    func firstName(fullName: String) -> String {
        var names = fullName.components(separatedBy: " ")
        let first = names.removeFirst()
        return first + "!"
    }
}


struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}
