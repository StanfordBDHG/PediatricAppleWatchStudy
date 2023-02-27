////
//// This source file is part of the CS342 2023 PAWS Team Application project
////
//// SPDX-FileCopyrightText: 2023 Stanford University
////
//// SPDX-License-Identifier: MIT
////
//
// import SwiftUI
//
//
// struct LatestRecording: View {
//    private let backgroundGradient = LinearGradient(
//        colors: [.white],
//        startPoint: .leading,
//        endPoint: .trailing
//    )
//    
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack(alignment: .top, spacing: 8) {
//                Text("ECG Recording")
//                    .font(.headline)
//                    .padding([.trailing, .top], 20)
//                    .padding([.leading], 10)
//                    .padding([.bottom], 1)
//                    .fontWeight(.bold)
//                
//                    Text("12:30 PM")
//                        .font(.subheadline)
//                        .padding([.top], 22)
//                        .padding([.leading], 40)
//            }
//            Text("Feb 6, 2023")
//                .font(.subheadline)
//                .padding([.leading, .bottom], 10)
//           
//            HStack(alignment: .top, spacing: 8) {
//                Text("Successfully uploaded")
//                    .font(.callout)
//                    .padding([.leading, .bottom], 10)
//                    .foregroundColor(.gray)
//                Image(systemName: "checkmark.circle.fill")
//                    .foregroundColor(.green)
//                    .imageScale(.large)
//                    .padding([.leading], 60)
//            }
//            .padding([.top], 1)
//            .padding([.bottom], 20)
//            RecordingsNav()
//        }
//        .frame(width: 320)
//        .border(.gray, width: 1)
//        .cornerRadius(10)
//    }
// }
//
//
// struct LatestRecording_Previews: PreviewProvider {
//    static var previews: some View {
//        LatestRecording()
//    }
// }
