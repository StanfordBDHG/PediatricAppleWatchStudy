//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseAuth
import FirebaseFirestore


extension FirebaseFirestore.Firestore {
    enum FirestoreError: Error {
        case userNotAuthenticatedYet
        case userDetailsNotLoading
    }
    
    
    nonisolated var userCollectionReference: CollectionReference {
        self.collection("users")
    }
    
    nonisolated var userDocumentReference: DocumentReference {
        get async throws {
            guard let accountId = Auth.auth().currentUser?.uid else {
                throw FirestoreError.userNotAuthenticatedYet
            }

            return userCollectionReference.document(accountId)
        }
    }
    
    nonisolated var healthKitCollectionReference: CollectionReference {
        get async throws {
            try await self.userDocumentReference.collection("HealthKit")
        }
    }
}
