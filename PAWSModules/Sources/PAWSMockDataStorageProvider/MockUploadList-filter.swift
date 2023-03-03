//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


/// Displays the recoded uploads collected by the ``MockDataStorageProvider``.
public struct MockUploadListFilter: View {
    @EnvironmentObject var mockDataStorageProvider: MockDataStorageProvider
    let button1: some View =
        Text("Past week")
            .fontWeight(.bold)
            .font(.system(size: 8))
            .padding()
            .background(Color.purple)
            .cornerRadius(10)
            .foregroundColor(.white)
            .padding(5)
    
    public var body: some View {
            VStack(alignment: .leading) {
              Text(String(localized: "MOCK_UPLOAD_LIST_TITLE", bundle: .module))
                        .font(.title)
                        .fontWeight(.bold)
                        .padding([.top, .bottom], 20)
                HStack(spacing: 3) {
                    button1
                    .frame(maxWidth: .infinity)
                    button1
                    .frame(maxWidth: .infinity)
                    button1
                    .frame(maxWidth: .infinity)
                }
               
                Group {
                    if mockDataStorageProvider.mockUploads.isEmpty {
                        VStack(spacing: 32) {
                            Image(systemName: "pawprint.circle")
                                .font(.system(size: 100))
                                .opacity(0.2)
                            Text(String(localized: "MOCK_UPLOAD_LIST_PLACEHOLDER", bundle: .module))
                                .multilineTextAlignment(.center)
                        }
                        .padding(32)
                    } else {
                        List(mockDataStorageProvider.mockUploads) { mockUpload in
                            MockUploadHeader(mockUpload: mockUpload)
                        }
                    }
                }
            }
    }
    
    
    public init() {}
    
    
    private func format(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long
        return dateFormatter.string(from: date)
    }
}


struct MockUploadsListFilter_Previews: PreviewProvider {
    static var previews: some View {
        MockUploadListFilter()
            .environmentObject(MockDataStorageProvider())
    }
}
