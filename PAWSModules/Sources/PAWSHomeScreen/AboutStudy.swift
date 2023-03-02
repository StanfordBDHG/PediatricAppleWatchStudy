//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct AboutStudy: View {
    private let backgroundGradient = LinearGradient(
        colors: [.red, .pink, .orange],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack {
                Image(systemName: "pawprint.circle.fill")
                    .resizable()
                    //.aspectRatio(contentMode: .fit)
                    .scaledToFill()
                    .frame(width: 115, height: 75)
                    .foregroundColor(.red)
                    .padding([.top, .leading, .trailing], 20)
                    //.offset(x:80, y:-5)
            }
            .padding([.top, .leading, .trailing, .bottom], 20)
            .cornerRadius(10)
            .offset(x: 75)
            VStack(alignment: .leading, spacing: 8) {
                Text("Contribute to Health Research")
                    .font(.headline)
                    .padding([.trailing], 20)
                    .padding([.leading], 10)
                    .padding([.bottom], 1)
                    .fontWeight(.bold)
                    .offset(x: 50, y:-10)
                
                Text("Find out how you're helping the Stanford Pediatric Apple Watch Study (PAWS).")
                        .font(.subheadline)
                        .padding([.top, .bottom], 10)
                        .padding([.leading], 10)
                        .offset(y:-10)
            }
            .offset(y: 10)
            .cornerRadius(10)
            .padding([.top], 1)
            .padding([.bottom], 20)
            AboutStudyNav()
                .offset(x: 27)
        }
        .frame(width: 380)
        .border(.gray, width: 1)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}


struct AboutStudy_Previews: PreviewProvider {
    static var previews: some View {
        LatestRecording()
    }
}
