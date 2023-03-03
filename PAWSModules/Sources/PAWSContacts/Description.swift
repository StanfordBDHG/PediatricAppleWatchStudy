//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI

struct DescriptionView: View {
    private let backgroundGradient = LinearGradient(
        colors: [.red, .pink, .yellow],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        VStack(spacing: 1) {
            Text("DESCRIPTION")
                .font(.custom("Gill Sans", fixedSize: 28))
                .padding()
            Text(description)
                .font(.custom("GillSans", fixedSize: 18))
                .padding()
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color(.systemBackground))
                        .frame(width: 360)
                        .shadow(radius: 5)
                        .opacity(0.9)
                        .border(backgroundGradient, width: 5)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
                .padding(.horizontal)
                .padding(.vertical, 2)
        }
    }
    
    private var description: String {
        guard let descriptionPath = Bundle.module.path(forResource: "StudyDescription", ofType: "md"),
              let description = try? String(contentsOfFile: descriptionPath) else {
            return ""
        }
        
        return description
    }
}

struct DescriptionView_Previews: PreviewProvider {
    static var previews: some View {
        DescriptionView()
    }
}
