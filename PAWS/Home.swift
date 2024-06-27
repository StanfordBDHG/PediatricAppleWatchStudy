//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziAccount
import SwiftUI


struct HomeView: View {
    enum Tabs: String {
        case schedule
        case contact
        case studyInformation
        case mockUpload
    }
    
    static var accountEnabled: Bool {
        !FeatureFlags.disableFirebase && !FeatureFlags.skipOnboarding
    }


    @AppStorage(StorageKeys.homeTabSelection) private var selectedTab = Tabs.schedule
    @State private var presentingAccount = false

    
    var body: some View {
        TabView(selection: $selectedTab) {
            ECGRecordingsList(presentingAccount: $presentingAccount)
                .tag(Tabs.schedule)
                .tabItem {
                    Label("ECG Recordings", systemImage: "waveform.path.ecg")
                }
            StudyInformation(presentingAccount: $presentingAccount)
                .tag(Tabs.studyInformation)
                .tabItem {
                    Label("Infos", systemImage: "i.circle")
                }
            Contacts(presentingAccount: $presentingAccount)
                .tag(Tabs.contact)
                .tabItem {
                    Label("Contacts", systemImage: "person.fill")
                }
        }
            .sheet(isPresented: $presentingAccount) {
                AccountSheet()
            }
            .accountRequired(Self.accountEnabled) {
                AccountSheet()
            }
            .verifyRequiredAccountDetails(Self.accountEnabled)
    }
}


#if DEBUG
#Preview {
    let details = AccountDetails.Builder()
        .set(\.userId, value: "lelandstanford@stanford.edu")
        .set(\.name, value: PersonNameComponents(givenName: "Leland", familyName: "Stanford"))
    
    return HomeView()
        .previewWith(standard: PAWSStandard()) {
            PAWSScheduler()
            AccountConfiguration(building: details, active: MockUserIdPasswordAccountService())
        }
}

#Preview {
    CommandLine.arguments.append("--disableFirebase")
    return HomeView()
        .previewWith(standard: PAWSStandard()) {
            PAWSScheduler()
            AccountConfiguration {
                MockUserIdPasswordAccountService()
            }
        }
}
#endif
