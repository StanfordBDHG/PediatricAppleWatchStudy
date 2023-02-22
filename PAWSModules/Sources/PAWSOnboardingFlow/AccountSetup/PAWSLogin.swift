//
// This source file is part of the Stanford CardinalKit PAWS Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Account
import Onboarding
import SwiftUI


struct PAWSLogin: View {
    var body: some View {
        Login {
            IconView()
                .padding(.top, 32)
            Text("LOGIN_SUBTITLE", bundle: .module)
                .multilineTextAlignment(.center)
                .padding()
                .padding()
            Spacer(minLength: 0)
        }
            .navigationBarTitleDisplayMode(.large)
    }
}


#if DEBUG
struct PAWSLogin_Previews: PreviewProvider {
    static var previews: some View {
        PAWSLogin()
            .environmentObject(Account(accountServices: []))
    }
}
#endif
