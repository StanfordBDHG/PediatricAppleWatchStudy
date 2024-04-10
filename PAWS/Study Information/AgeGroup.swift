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
class AgeGroup: Module, EnvironmentAccessible {
    // Dependency toward spezi configuration firebase
    @ObservationIgnored @Dependency var accountConfiguration: FirebaseAccountConfiguration?
    @ObservationIgnored @Environment(Account.self) var account
    var dateOfBirth: Date?
    // get field for specific document path is there a Boolean value for adultStudy
    // onsignup function checks user's date of birth and signup date, checks if something is already in firestore
    
    var studyType: StudyType? {
        guard let enrollmentDate = Auth.auth().currentUser?.metadata.creationDate,
              let dateOfBirth,
              let ageYears = Calendar.current.dateComponents([.year], from: dateOfBirth, to: enrollmentDate).year else {
            return nil
        }
        
        return ageYears >= 18 ? .adult : .pediatric
    }
    
    init() { }
    
    // configure method of spezi module
    func configure() {
        // check if user is authenticated
        guard Auth.auth().currentUser != nil else {
            return
        }
        // within configure method, query user and store as a user property in firestore

        // is date of birth stored in there and study enrollment time
        // if yes, calculate and store in studyType property
        // snapshot listeners to observe changes to user document
        // firebase listener change in user logged in
        // create snapshot listener to users
        Task {
            self.dateOfBirth = await account.details?.dateOfBrith
        }
    }
    
    // consider getting the dateofbirth from firestore directly
}
