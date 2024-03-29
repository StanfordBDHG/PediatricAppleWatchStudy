//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Firebase
import FirebaseAuth
import FirebaseFunctions
import SpeziOnboarding
import SpeziValidation
import SpeziViews
import SwiftUI


struct InvitationCodeView: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    @State private var invitationCode = ""
    @State private var viewState: ViewState = .idle
    @ValidationState private var validation
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                invitationCodeHeader
                Divider()
                Grid(horizontalSpacing: 16, verticalSpacing: 16) {
                    invitationCodeView
                }
                    .padding(.top, -8)
                    .padding(.bottom, -12)
                Divider()
                OnboardingActionsView(
                    "Redeem Invitation Code",
                    action: {
                        guard validation.validateSubviews() else {
                            return
                        }
                        
                        /*if Auth.auth().currentUser == nil {
                            async let authResult =  Auth.auth().signInAnonymously()
                            print("Auth result: ", try await authResult)
                        }*/
                        await verifyOnboardingCode()
                    }
                )
                    .disabled(invitationCode.isEmpty)
            }
                .padding(.horizontal)
                .padding(.bottom)
                .viewStateAlert(state: $viewState)
                .navigationBarTitleDisplayMode(.large)
                .navigationTitle(String(localized: "Invitation Code"))
        }
    }
    
    
    @ViewBuilder private var invitationCodeView: some View {
        DescriptionGridRow {
            Text("Invitation Code")
        } content: {
            VerifiableTextField(
                LocalizedStringResource("Invitation Code"),
                text: $invitationCode
            )
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.characters)
                .textContentType(.oneTimeCode)
                .validate(input: invitationCode, rules: [invitationCodeValidationRule])
        }
            .receiveValidation(in: $validation)
    }
    
    @ViewBuilder private var invitationCodeHeader: some View {
        VStack(spacing: 32) {
            Image(systemName: "rectangle.and.pencil.and.ellipsis")
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .accessibilityHidden(true)
                .foregroundStyle(Color.accentColor)
            Text("Plase enter your invitation code to join the PAWS study.")
        }
    }
    
    private var invitationCodeValidationRule: ValidationRule {
        ValidationRule(
            rule: { invitationCode in
                invitationCode.count >= 8
            },
            message: "An invitation code is at least 8 characters long."
        )
    }
    
    init() {
        if FeatureFlags.useFirebaseEmulator {
            Functions.functions().useEmulator(withHost: "localhost", port: 5001)
        }
    }
    
    private func verifyOnboardingCode() async {
        do {
            if FeatureFlags.disableFirebase {
                guard invitationCode == "VASCTRAC" else {
                    throw InvitationCodeError.invitationCodeInvalid
                }
                
                try? await Task.sleep(for: .seconds(0.25))
            } else {
                if Auth.auth().currentUser == nil {
                    async let authResult = Auth.auth().signInAnonymously()
                    print("Auth result: ", try await authResult.user.uid)
                    
                    let checkInvitationCode = Functions.functions().httpsCallable("checkInvitationCode")
                    
                    do {
                        _ = try await checkInvitationCode.call(
                            [
                                "invitationCode": invitationCode,
                                "userId": authResult.user.uid
                            ]
                        )
                    } catch {
                        throw InvitationCodeError.invitationCodeInvalid
                    }
                }
            }
            
            await onboardingNavigationPath.nextStep()
        } catch let error as NSError {
                if let errorCode = FunctionsErrorCode(rawValue: error.code) {
                    // Handle Firebase-specific errors.
                    switch errorCode {
                    case .unauthenticated:
                        viewState = .error(InvitationCodeError.userNotAuthenticated)
                    case .notFound:
                        viewState = .error(InvitationCodeError.invitationCodeInvalid)
                    default:
                        viewState = .error(InvitationCodeError.generalError(error.localizedDescription))
                    }
                } else {
                    // Handle other errors, such as network issues or unexpected behavior.
                    viewState = .error(InvitationCodeError.generalError(error.localizedDescription))
                }
            }
    }
}


#Preview {
    FirebaseApp.configure()
    
    return OnboardingStack {
        InvitationCodeView()
    }
}
