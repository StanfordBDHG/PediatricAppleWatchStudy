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


struct PAWSSignUp: View {
    var body: some View {
        SignUp {
            IconView()
                .padding(.top, 32)
            Text("SIGN_UP_SUBTITLE", bundle: .module)
                .multilineTextAlignment(.center)
                .padding()
            Spacer(minLength: 0)
        }
            .navigationBarTitleDisplayMode(.large)
    }
}


#if DEBUG
struct PAWSSignUp_Previews: PreviewProvider {
    static var previews: some View {
        PAWSSignUp()
            .environmentObject(Account(accountServices: []))
    }
}
#endif
