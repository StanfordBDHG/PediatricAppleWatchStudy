//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct Notification: View {
    private let backgroundGradient = LinearGradient(
        colors: [.red, .pink, .yellow],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("February 8th, 2023")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            VStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ECG Recording")
                            .font(.headline)
                            .padding([.leading, .trailing, .top], 20)
                            .fontWeight(.bold)
                        
                            Text("12:30 PM")
                                .font(.subheadline)
                            .padding([.leading, .trailing], 20)
                    }
             
                Divider()
            HStack {
                Text("Recording successfully uploaded")
                    .font(.callout)
                    .padding()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            }
            .frame(width: 320)
            .opacity(0.9)
            .border(backgroundGradient, width: 5)
            .cornerRadius(10)
            .shadow(radius: 10)
        }
    }
}


struct Notification_Previews: PreviewProvider {
    static var previews: some View {
        Notification()
    }
}
