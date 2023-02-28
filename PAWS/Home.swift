//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import PAWSContacts
import PAWSHomeScreen
import PAWSMockDataStorageProvider
import PAWSNotificationScreen
import PAWSSharedContext
import SwiftUI


struct HomeView: View {
    enum Tabs: String {
        case contact
        case mockUpload
//        case home
    }
    
    
    @AppStorage(StorageKeys.homeTabSelection) var selectedTab = Tabs.mockUpload
    
    
    var body: some View {
        TabView(selection: $selectedTab) {
//            PAWSHomeScreen()
//                .tag(Tabs.home)
//                .tabItem {
//                    Label("Home", systemImage: "house.fill")
//                }
            MockUploadList()
                .tag(Tabs.mockUpload)
                .tabItem {
                    Label("MOCK_UPLOAD_TAB_TITLE", systemImage: "server.rack")
                }
            Contacts()
                .tag(Tabs.contact)
                .tabItem {
                    Label("CONTACTS_TAB_TITLE", systemImage: "person.fill")
                }
        }
    }
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
