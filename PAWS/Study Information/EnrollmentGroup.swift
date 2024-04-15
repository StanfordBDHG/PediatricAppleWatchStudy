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
    private var snapshotListener: ListenerRegistration?

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
        // Cancel the previous listener before registering a new one.
        snapshotListener?.remove()
        guard let uid = user?.uid else {
            return
        }
        snapshotListener = Firestore
            .firestore()
            .collection("users")
            .document(uid)
            .addSnapshotListener { [weak self] documentSnapshot, _ in
                if let data = documentSnapshot?.data() {
                    let dobTimestamp = data["DateOfBirthKey"] as? Timestamp
                    self?.dateOfBirth = dobTimestamp?.dateValue()
                }
            }
    }
}
