//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirestoreDataStorage
import Foundation
import HealthKitOnFHIR


struct MockUpload: Identifiable, Hashable {
    enum UploadType {
        case add
        case delete
    }
    
    enum UploadStatus {
        case success
        case failure
    }
    
    let identifier: String
    let date = Date()
    let type: UploadType
    let path: String
    let body: String?
    var symptoms: String?

    var id: String {
        "\(type): \(path)/\(identifier) at \(date.debugDescription)"
    }
    
    
    init(id: String, type: UploadType, path: String, body: String? = nil, symptoms: String? = "") {
        self.identifier = id
        self.type = type
        self.path = path
        self.body = body
        self.symptoms = symptoms
    }
}
