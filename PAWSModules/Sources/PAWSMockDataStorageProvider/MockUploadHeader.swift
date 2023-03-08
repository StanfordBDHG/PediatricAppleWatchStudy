//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable all

import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirestoreDataStorage
import SwiftUI

struct MockUploadHeader: View {
    let mockUpload: MockUpload
    @State var status: MockUpload.UploadStatus?
    private let backgroundGradient = LinearGradient(
        colors: [.red, .pink, .yellow],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        let date = "\(format(mockUpload.date))"
        let time = date.range(of: "at")!.lowerBound
        VStack(alignment: .leading, spacing: 4) {
                Text(date[..<time])
                .font(.title3)
                .bold()
                .padding([.bottom], 3)
                .padding([.leading], 8)
            Text(date[date.index(time, offsetBy: 2)...])
                .font(.subheadline)
                .padding(.bottom, 10)
                .padding(.leading, 8)
            Divider()
            Text(mockUpload.symptoms ?? "No symptoms")
            Divider()
            statusView.onAppear(perform: checkStatus)
                .padding(8)
                .cornerRadius(4)
        }
        .frame(width: 350, height: 110)
//        .border(backgroundGradient, width: 5)
      
    }
    
    @ViewBuilder var statusView: some View {
        switch status {
        case .success:
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Recording successfully uploaded!")
            }
            .background(Color.green.opacity(0.3))
        case .failure:
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "x.circle.fill")
                    .foregroundColor(.red)
                Text("Recording upload is pending")
            }
            .background(Color.red.opacity(0.3))
  
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
