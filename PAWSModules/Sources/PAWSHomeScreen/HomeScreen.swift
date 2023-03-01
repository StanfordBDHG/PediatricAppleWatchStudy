//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI
import FirebaseAuth

public struct HomeScreen: View {
    private let backgroundGradient = LinearGradient(
        colors: [.red, .pink, .orange, .yellow],
        startPoint: .leading,
        endPoint: .trailing
    )
    public var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text("Hello,")
                            .padding([.top], 10)
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Your Name")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding([.top], 0)
                            .padding([.bottom], 10)
                    }
                    Image(systemName: "pawprint.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.black)
                        .padding([.top], 10)
                        .padding([.leading], 120)
                }.padding([.top, .leading, .trailing], 10)
                Divider()
                VStack(alignment: .leading) {
                    LatestRecording()
                }.padding([.top, .leading, .trailing], 10)
                
                VStack(alignment: .leading) {
                    Text("About The Study")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding([.top], 10)
                        .foregroundColor(.gray)
                    AboutStudy()
                }.padding([.top, .leading, .trailing], 10)
            }
        }
    }
    
    
    public init() {}
}


struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}
