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
    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?

    var studyType: StudyType? {
        guard let enrollmentDate = Auth.auth().currentUser?.metadata.creationDate,
              let dateOfBirth,
              let yearsOfAge = Calendar.current.dateComponents([.year], from: dateOfBirth, to: enrollmentDate).year else {
            return nil
        }
        return yearsOfAge >= 18 ? .adult : .pediatric
    }
    
    func configure() {
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.registerSnapshotListener(user: user)
        }
        self.registerSnapshotListener(user: Auth.auth().currentUser)
    }
    
    func registerSnapshotListener(user: User?) {
        guard let uid = user?.uid else {
            return
        }
        Firestore
            .firestore()
            .collection("users")
            .document(uid)
            .addSnapshotListener { documentSnapshot, error in
                /*guard error != nil else {
                    // throw error?
                    print(error)
                    return
                }*/
                
                if let data = documentSnapshot?.data() {
                    let dobTimestamp = data["DateOfBirthKey"] as? Timestamp
                    self.dateOfBirth = dobTimestamp?.dateValue()
                }
            }
    }
    
    /*deinit {
        if let handle = authStateDidChangeListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }*/
}
