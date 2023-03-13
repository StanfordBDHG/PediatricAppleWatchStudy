//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//
import PAWSSharedContext
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
            Image(uiImage: Bundle.module.image(withName: "circleLogo", fileExtension: "png"))
                        .resizable()
                        .frame(width: 225, height: 225)
                        .accessibilityLabel(Text("App Icon"))
                        .padding(.bottom)
                    Text("PAWS")
                        .font(.custom("GillSans-Bold", fixedSize: 30))
                    Text("The Pediatric Apple Watch Study")
                        .font(.custom("GillSans", fixedSize: 15))
                        .offset(y: 10)

            Button(
                action: {
                    launchStatus = true
                }, label: {
                Text("Tap to get started")
                    .fontWeight(.bold)
                    .padding()
                    .foregroundColor(Color.black)
                    .border(.yellow.opacity(0.5), width: 5)
                    .cornerRadius(5)
                    .offset(y: -30)
                    .offset(y: 150)
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
