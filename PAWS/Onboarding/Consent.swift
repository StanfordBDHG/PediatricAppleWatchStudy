//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziConsent
import SpeziOnboarding
import SpeziViews
import SwiftUI


/// - Note: The `OnboardingConsentView` exports the signed consent form as PDF to the Spezi `Standard`, necessitating the conformance of the `Standard` to the `OnboardingConstraint`.
struct Consent: View {
    @Environment(ManagedNavigationStack.Path.self) private var managedNavigationStack
    @Environment(PAWSStandard.self) private var standard: PAWSStandard
    
    @State private var consentDocument: ConsentDocument?
    @State private var viewState: ViewState = .idle
    
    
    var body: some View {
        OnboardingConsentView(
            consentDocument: consentDocument,
            viewState: $viewState
        ) {
            guard let consentDocument else {
                return
            }
            
            try await standard.store(consentDocument: consentDocument)
            managedNavigationStack.nextStep()
        }
        .viewStateAlert(state: $viewState)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ConsentShareButton(
                    consentDocument: consentDocument,
                    viewState: $viewState
                )
            }
        }
        .task {
            do {
                guard let url = Bundle.main.url(forResource: "ConsentDocument", withExtension: "md") else {
                    fatalError("Consent document not found in main bundle.")
                }
                consentDocument = try ConsentDocument(contentsOf: url)
            } catch {
                viewState = .error(AnyLocalizedError(error: error))
            }
        }
    }
}


#if DEBUG
#Preview {
    ManagedNavigationStack {
        Consent()
    }
        .previewWith(standard: PAWSStandard()) {}
}
#endif
