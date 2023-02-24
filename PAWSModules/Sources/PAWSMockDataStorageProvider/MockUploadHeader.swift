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
import SwiftUI

struct MockUploadHeader: View {
    let mockUpload: MockUpload
    @State var status: MockUpload.UploadStatus?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 12) {
                switch mockUpload.type {
                case .add:
                    Image(systemName: "arrow.up.doc.fill")
                        .foregroundColor(.blue)
                case .delete:
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                }
                Text("\(mockUpload.path)")
            }
                .font(.title3)
                .bold()
                .padding(.bottom, 12)
            
            statusView.onAppear(perform: checkStatus)
            
            Text("On \(format(mockUpload.date))")
                .font(.subheadline)
            Text("\(mockUpload.identifier)")
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }
    
    @ViewBuilder var statusView: some View {
        switch status {
        case .success:
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .foregroundColor(.green)
                Text("Recording successfully uploaded!")
            }
            .padding(.bottom, 6)
        case .failure:
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "person.crop.circle.badge.minus")
                    .foregroundColor(.red)
                Text("Recording upload is pending")
            }
            .padding(.bottom, 6)
        case nil:
            Text("Loading status indicator")
        }
    }
    
    private func format(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long
        return dateFormatter.string(from: date)
    }
    
    private func checkStatus() {
        let user = Auth.auth().currentUser
        let uid = user?.uid ?? ""
        let id = mockUpload.identifier
        
        let dbs = Firestore.firestore()
        let uploadRef = dbs.collection("users").document(uid).collection("Observation").document(id)
                    
        uploadRef.getDocument { document, _ in
            if let document = document, document.exists {
                self.status = .success
            } else {
                self.status = .failure
            }
        }
    }
}
