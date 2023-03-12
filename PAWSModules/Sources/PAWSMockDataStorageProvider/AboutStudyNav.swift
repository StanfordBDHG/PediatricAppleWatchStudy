//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import PAWSSharedContext
import SwiftUI


struct AboutStudyNav: View {
    private let backgroundGradient = LinearGradient(
        colors: [.red, .pink, .orange],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    @AppStorage(StorageKeys.homeTabSelection) var selectedTab = Tabs.home
    
    var body: some View {
        Button(
            action: {
                selectedTab = Tabs.contact
            }, label: {
            Text("Learn More                                                                              ")
                .fontWeight(.bold)
                .padding()
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(backgroundGradient)
                .cornerRadius(10)
                .padding(.bottom, 10)
            }
        )
    }
}

struct AboutStudyNav_Previews: PreviewProvider {
    static var previews: some View {
        AboutStudyNav()
    }
}
