//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


public struct NotificationScreen: View {
    public var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                Text("Notifications")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding([.top, .bottom], 20)
                Notification()
                Notification()
                Notification()
                Notification()
            }
        }
    }
    
    
    public init() {}
}


struct NotificationScreen_Previews: PreviewProvider {
    static var previews: some View {
        NotificationScreen()
    }
}
