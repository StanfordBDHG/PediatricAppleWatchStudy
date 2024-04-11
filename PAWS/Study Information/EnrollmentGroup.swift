//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseAuth
import FirebaseFirestore
import Spezi
import SpeziAccount
import SpeziFirebaseConfiguration
import SwiftUI


@Observable
class EnrollmentGroup: Module, EnvironmentAccessible {
    @ObservationIgnored @Dependency private var configureFirebaseApp: ConfigureFirebaseApp
    private var dateOfBirth: Date?
    
    
    var studyType: StudyType? {
        guard let enrollmentDate = Auth.auth().currentUser?.metadata.creationDate,
              let dateOfBirth,
              let yearsOfAge = Calendar.current.dateComponents([.year], from: dateOfBirth, to: enrollmentDate).year else {
            return nil
        }
        return yearsOfAge >= 18 ? .adult : .pediatric
    }
    
    func configure() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        Firestore
            .firestore()
            .collection("users")
            .document(uid)
            .addSnapshotListener { documentSnapshot, _ in
                if let data = documentSnapshot?.data() {
                    let dobTimestamp = data["DateOfBirthKey"] as? Timestamp
                    self.dateOfBirth = dobTimestamp?.dateValue()
                }
            }
    }
}
