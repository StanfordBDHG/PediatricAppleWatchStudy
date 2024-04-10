//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseAuth
import Spezi
import SpeziAccount
import SpeziFirebaseAccount
import SwiftUI


@Observable
class EnrollmentGroup: Module, EnvironmentAccessible {
    @ObservationIgnored @Dependency var accountConfiguration: FirebaseAccountConfiguration?
    @ObservationIgnored @Environment(Account.self) var account
    var dateOfBirth: Date?
    
    var studyType: StudyType? {
        guard let enrollmentDate = Auth.auth().currentUser?.metadata.creationDate,
              let dateOfBirth,
              let ageYears = Calendar.current.dateComponents([.year], from: dateOfBirth, to: enrollmentDate).year else {
            return nil
        }
        return ageYears >= 18 ? .adult : .pediatric
    }
    
    init() { }
    
    func configure() {
        guard Auth.auth().currentUser != nil else {
            return
        }
        Task {
            self.dateOfBirth = await account.details?.dateOfBrith
        }
    }
}
