//
// This source file is part of the Stanford Spezi Study Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


enum InvitationCodeError: LocalizedError {
    case invitationCodeInvalid
    
    
    var errorDescription: String? {
        switch self {
        case .invitationCodeInvalid:
            String(localized: "Invitation code was invalid.")
        }
    }
}
