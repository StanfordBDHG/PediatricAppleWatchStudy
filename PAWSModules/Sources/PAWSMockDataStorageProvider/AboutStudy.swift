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
                    // .aspectRatio(contentMode: .fit)
                    .scaledToFill()
                    .frame(width: 115, height: 75)
                    .foregroundColor(.red)
                    .padding([.top], 20)
                    // .offset(x: 8)
                    // .offset(x:80, y:-5)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding([.top, .leading, .trailing, .bottom], 20)
            VStack(alignment: .leading, spacing: 8) {
                Text("Contribute to Health Research")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text("Find out how you're helping the Stanford Pediatric Apple Watch Study (PAWS).")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.top, .bottom, .leading, .trailing], 10)
                        // .offset(y:-10)
            }
            .offset(y: 10)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding([.top], 1)
            .padding([.bottom], 20)
            AboutStudyNav().padding([.leading, .trailing], 10)
        }
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 10).strokeBorder(.gray, lineWidth: 1)
        )
    }
}


struct AboutStudy_Previews: PreviewProvider {
    static var previews: some View {
        AboutStudy()
    }
}
