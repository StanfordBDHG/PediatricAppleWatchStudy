//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


enum InvitationCodeError: LocalizedError {
    case invitationCodeInvalid
    case userNotAuthenticated
    case generalError(String)
    
    var errorDescription: String? {
        switch self {
        case .invitationCodeInvalid:
            String(localized: "The invitation code is invalid or has already been used.", comment: "Invitation Code Invalid")
        case .userNotAuthenticated:
            String(localized: "User authentication failed. Please try to sign in again.", comment: "User Not Authenticated")
        case .generalError(let message):
            String(localized: "An error occurred: \(message)", comment: "General Error")
        }
    }
}
