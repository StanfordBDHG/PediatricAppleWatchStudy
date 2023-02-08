//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI

struct LandingScreen: View {
//    @AppStorage(StorageKeys.accountCreated) var completedAccountSetup = false

    var body: some View {
        VStack {
            LinearGradient(
                colors: [.red, .pink, .orange, .yellow],
                startPoint: .leading,
                endPoint: .trailing
            )
            .mask(
                VStack {
                    Image(systemName: "pawprint.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .foregroundColor(.red)
                    Text("PAWS")
                        .font(.custom("GillSans-Bold", fixedSize: 30))
                    Text("The Pediatric Apple Watch Study")
                        .font(.custom("GillSans", fixedSize: 15))
                        .offset(y: 50)
                    
                    Button(action: {
        //                completedAccountSetup = true
                    }) {
                        
                        Text("Tap to get started")
                            .fontWeight(.bold)
                            .padding()
                            .foregroundColor(.white)
                            .border(Color.black, width: 3)
//                            .background(Color.black)
                            .cornerRadius(5)
                            .offset(y: 100)
                            
                    }
                    
                }
            )

//            Button(action: {
////                completedAccountSetup = true
//            }) {
//                HStack {
//                    Image(systemName: "apple.logo")
//                        .font(.title)
//                    Text("Sign in with Apple")
//                        .fontWeight(.bold)
//
//                }
//                .padding()
//                .foregroundColor(.white)
//                .background(Color.black)
//                .cornerRadius(30)
//                .offset(y: -50)
//            }
        }
    }
}

struct LandingScreen_Previews: PreviewProvider {
    static var previews: some View {
        LandingScreen()
    }
}
