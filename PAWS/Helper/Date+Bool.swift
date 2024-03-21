//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension Date {
    var isAdultDateOfBirth: Bool {
        let ageComponents = Calendar.current.dateComponents([.year], from: self, to: .now)
        guard let ageYears = ageComponents.year else {
            return false
        }
        
        return ageYears >= 18
    }
}
