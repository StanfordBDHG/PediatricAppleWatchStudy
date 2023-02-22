//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct MockUploadHeader: View {
    let mockUpload: MockUpload
    
    
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
            
            switch mockUpload.status {
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
            }
            
            Text("On \(format(mockUpload.date))")
                .font(.subheadline)
            Text("\(mockUpload.identifier)")
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }
    
    
    private func format(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long
        return dateFormatter.string(from: date)
    }
}
