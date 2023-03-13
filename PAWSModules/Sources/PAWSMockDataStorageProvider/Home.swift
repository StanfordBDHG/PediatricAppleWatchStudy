//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import PAWSContacts
import PAWSNotificationScreen
import PAWSSharedContext
import SwiftUI


enum Tabs: String {
    case home
    case contact
    case mockUpload
}

public struct HomeView: View {
    @AppStorage(StorageKeys.homeTabSelection) var selectedTab = Tabs.home
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            HomeScreen()
                .tag(Tabs.home)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            MockUploadList()
                .tag(Tabs.mockUpload)
                .tabItem {
                    Label("Reports", systemImage: "heart.text.square.fill")
                }
            Contacts()
                .tag(Tabs.contact)
                .tabItem {
                    Label("Study Information", systemImage: "doc.text.fill")
                }
        }
    }
    public init() {}
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
