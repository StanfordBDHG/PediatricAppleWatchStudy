//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct PAWSCard<Content: View>: View {
    private let content: Content
    
    
    var body: some View {
        Group {
            content
        }
            .cornerRadius(5)
            .padding(3)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(
                            LinearGradient(
                                colors: [.red, .pink, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 4
                        )
                        .shadow(radius: 5)
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(.background)
                }
            )
            .padding(.horizontal)
    }
    
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
}


#Preview {
    PAWSCard {
        Text(verbatim: "This is an example content ...")
    }
}
