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
import Foundation
import SwiftUI


struct LatestRecording: View {
    let mockUpload: MockUpload
    @State var status: MockUpload.UploadStatus?
    
    private let backgroundGradient = LinearGradient(
        colors: [.white],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        let date = "\(format(mockUpload.date))"
        let time = date.range(of: "at")!.lowerBound
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text("ECG Recording")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.top, .bottom, .leading, .trailing], 10)
                    .fontWeight(.bold)
                Text(date[date.index(time, offsetBy: 2)...])
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding([.top, .bottom, .leading, .trailing], 10)
                    
            }
            Text(date[..<time])
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.leading, .bottom], 10)
            statusView.onAppear(perform: checkStatus)
                .frame(maxWidth: .infinity)
                .padding([.top], 5)
                .padding([.bottom], 10)
        }
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 10).strokeBorder(.gray, lineWidth: 1)
        )
    }
    
    @ViewBuilder var statusView: some View {
        switch status {
        case .success:
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .imageScale(.large)
                    .padding([.leading, .bottom], 10)
                Text("Successfully uploaded")
                    .font(.callout)
                    .padding([.leading, .bottom], 10)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.top], 1)
            .padding([.bottom], 10)
            RecordingsNav()
                .padding([.leading, .trailing], 10)
        case .failure:
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "x.circle.fill")
                    .foregroundColor(.red)
                    .imageScale(.large)
                    .padding([.leading, .bottom], 10)
                Text("Upload pending")
                    .font(.callout)
                    .padding([.leading, .bottom], 10)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.top], 1)
            .padding([.bottom], 10)
            RecordingsNav()
                .padding([.leading, .trailing], 10)
        case nil:
            Text("Loading status indicator")
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.leading, .bottom], 10)
                .foregroundColor(.gray)
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
