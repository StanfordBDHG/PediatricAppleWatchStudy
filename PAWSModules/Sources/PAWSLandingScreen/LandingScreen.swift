//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


public struct LandingScreen: View {
    private let backgroundGradient = LinearGradient(
        colors: [.red, .pink, .orange, .yellow],
        startPoint: .leading,
        endPoint: .trailing
    )
    @Binding private var launchStatus: Bool
    
    
    public var body: some View {
        VStack {
            backgroundGradient
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
                }
            )
            Button(
                action: {
                    launchStatus = true
                }, label: {
                Text("Tap to get started")
                    .fontWeight(.bold)
                    .padding()
                    .foregroundColor(Color.red)
                    .border(backgroundGradient, width: 3)
                    .cornerRadius(5)
                    .offset(y: -30)
                }
            )
        }
    }
    
    
    public init(pressedStart: Binding<Bool>) {
        self._launchStatus = pressedStart
    }
}


struct LandingScreen_Previews: PreviewProvider {
    @State private static var pressedStart = false
    
    static var previews: some View {
        LandingScreen(pressedStart: $pressedStart)
    }
}
