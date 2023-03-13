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
        //let symptomNum = seperateSymptoms(allSymptoms: mockUpload.symptoms ?? "").count

        ZStack{
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color(.systemBackground))
                .frame(width: 360)
                .shadow(radius: 5)
                .opacity(0.9)
                .border(backgroundGradient, width: 2)
                .cornerRadius(10)
                .shadow(radius: 10)
            VStack(alignment: .leading, spacing: 4) {
                Text(date[..<time])
                    .font(.title3)
                    .bold()
                    .padding([.top, .bottom], 3)
                    .padding([.leading], 10)
                Text(date[date.index(time, offsetBy: 2)...])
                    .font(.subheadline)
                    .padding(.bottom, 10)
                    .padding(.leading, 10)
                Divider()
                symptomView
                    .padding(.bottom, 10)
                    .padding(.leading, 10)
                    .cornerRadius(4)
                Divider()
                statusView.onAppear(perform: checkStatus)
                    .padding(8)
                    .padding(.leading, 10)
                    .cornerRadius(4)
            }
        }
        
        //.frame(width: 350, height: 110 + CGFloat(30*symptomNum))
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
    
    @ViewBuilder var symptomView: some View {
        let symptoms = seperateSymptoms(allSymptoms: mockUpload.symptoms ?? "")
        if (symptoms.count <= 0) {
            Text("No Symptoms Reported")
                .bold()
                .padding([.top, .bottom], 3)
                .padding([.leading], 2)
        } else {
            Text("Symptoms Reported:")
                .bold()
                .padding([.top, .bottom], 3)
                .padding([.leading], 2)
            ForEach(symptoms) { symptom in
                Text(symptom)
                    .font(.subheadline)
                    .padding(.top, -4)
                    .padding(.bottom, -4)
                    .padding(.leading, 2)
            }
            
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
    
    private func seperateSymptoms(allSymptoms: String) -> [String] {
        var symptoms = allSymptoms.components(separatedBy: "; ")
        symptoms.removeLast()
        return symptoms
    }
}
