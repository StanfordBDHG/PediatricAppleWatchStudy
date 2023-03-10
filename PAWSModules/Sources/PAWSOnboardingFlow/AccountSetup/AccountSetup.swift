//
// This source file is part of the Stanford CardinalKit PAWS Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Account
import class FHIR.FHIR
import FirebaseAccount
import FirebaseAuth
import FirebaseFirestore
import Onboarding
import SwiftUI


struct AccountSetup: View {
    @Binding private var onboardingSteps: [OnboardingFlow.Step]
    @EnvironmentObject var account: Account
    private let backgroundGradient = LinearGradient(
        colors: [.red, .pink, .orange, .yellow],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        OnboardingView(
            contentView: {
                VStack {
                    OnboardingTitleView(
                        title: "ACCOUNT_TITLE".moduleLocalized,
                        subtitle: "ACCOUNT_SUBTITLE".moduleLocalized
                    )
                    Spacer(minLength: 0)
                    accountImage
                    accountDescription
                    Spacer(minLength: 0)
                }
            }, actionView: {
                actionView
            }
        )
            .onReceive(account.objectWillChange) {
                if account.signedIn {
                    onboardingSteps.append(.healthKitPermissions)
                    
                    if let user = Auth.auth().currentUser {
                        let uid = user.uid
                        let name = user.displayName?.components(separatedBy: " ")
                        let firstName = name?[0] ?? ""
                        let lastName = name?[1] ?? ""
                        let data: [String: Any] = ["firstName": firstName, "id": uid, "lastName": lastName]
                        Firestore.firestore().collection("users").document(uid).setData(data) { err in
                            if let err = err {
                                print("Error updating document: \(err)")
                            }
                        }
                    }
                    // Unfortunately, SwiftUI currently animates changes in the navigation path that do not change
                    // the current top view. Therefore we need to do the following async procedure to remove the
                    // `.login` and `.signUp` steps while disabling the animations before and re-enabling them
                    // after the elements have been changed.
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(1.0))
                        UIView.setAnimationsEnabled(false)
                        onboardingSteps.removeAll(where: { $0 == .login || $0 == .signUp })
                        try? await Task.sleep(for: .seconds(1.0))
                        UIView.setAnimationsEnabled(true)
                    }
                }
            }
    }
    
    @ViewBuilder
    private var accountImage: some View {
        Group {
            if account.signedIn {
                backgroundGradient
                .mask(
                    Image(systemName: "pawprint.circle.fill")
                )
            } else {
                backgroundGradient
                .mask(
                    VStack {
                        Image(systemName: "pawprint.circle")
                    }
                )
            }
        }
            .font(.system(size: 150))
            .foregroundColor(.accentColor)
    }
    
    @ViewBuilder
    private var accountDescription: some View {
        VStack {
            Group {
                if account.signedIn {
                    Text("ACCOUNT_SIGNED_IN_DESCRIPTION", bundle: .module)
                } else {
                    Text("ACCOUNT_SETUP_DESCRIPTION", bundle: .module)
                }
            }
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)
            if account.signedIn {
                UserView()
                    .padding()
            }
        }
    }
    
    @ViewBuilder
    private var actionView: some View {
        if account.signedIn {
            OnboardingActionsView(
                "ACCOUNT_NEXT".moduleLocalized,
                action: {
                    onboardingSteps.append(.healthKitPermissions)
                }
            )
        } else {
            OnboardingActionsView(
                primaryText: "ACCOUNT_SIGN_UP".moduleLocalized,
                primaryAction: {
                    onboardingSteps.append(.signUp)
                },
                secondaryText: "ACCOUNT_LOGIN".moduleLocalized,
                secondaryAction: {
                    onboardingSteps.append(.login)
                }
            )
        }
    }
    
    
    init(onboardingSteps: Binding<[OnboardingFlow.Step]>) {
        self._onboardingSteps = onboardingSteps
    }
}


#if DEBUG
struct AccountSetup_Previews: PreviewProvider {
    @State private static var path: [OnboardingFlow.Step] = []
    
    
    static var previews: some View {
        AccountSetup(onboardingSteps: $path)
            .environmentObject(Account(accountServices: []))
            .environmentObject(FirebaseAccountConfiguration<FHIR>(emulatorSettings: (host: "localhost", port: 9099)))
    }
}
#endif
