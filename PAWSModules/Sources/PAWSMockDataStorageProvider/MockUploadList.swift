//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


/// Displays the recoded uploads collected by the ``MockDataStorageProvider``.
public struct MockUploadList: View {
    @EnvironmentObject var mockDataStorageProvider: MockDataStorageProvider
    
    public var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            //        VStack(alignment: .leading) {
            //            Text("Notifications")
            //                .font(.largeTitle)
            //                .fontWeight(.bold)
            //                .padding([.top, .leading, .bottom], 20)
            //                .offset(y: -150)
            NavigationStack {
                Group {
                    if mockDataStorageProvider.mockUploads.isEmpty {
                        VStack(spacing: 30){
                            Image(uiImage: Bundle.module.image(withName: "notifLogo", fileExtension: "png"))
                                        .resizable()
                                        .frame(width: 150, height: 150, alignment: .center)
                                        .padding(.leading, 17)
                            VStack(spacing: 32) {
                                Text(String(localized: "MOCK_UPLOAD_LIST_PLACEHOLDER", bundle: .module))
                                    .multilineTextAlignment(.center)
                                    .fontWeight(.bold)
                            }
                            .padding(32)
                        }
                    } else {
                        List(mockDataStorageProvider.mockUploads) { mockUpload in
                            MockUploadHeader(mockUpload: mockUpload)
                        }
                    }
                }
                .navigationTitle(String(localized: "MOCK_UPLOAD_LIST_TITLE", bundle: .module))
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


struct MockUploadsList_Previews: PreviewProvider {
    static var previews: some View {
        MockUploadList()
            .environmentObject(MockDataStorageProvider())
    }
}
