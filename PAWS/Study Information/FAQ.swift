//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct FAQ: View {
    private struct Question: Identifiable {
        let question: LocalizedStringResource
        let answer: LocalizedStringResource
        
        
        var id: String {
            question.localizedString()
        }
    }
    
    
    private static var questions: [Question] = {
        (1...9).map { index in
            Question(
                question: LocalizedStringResource("QUESTION_\(index)"),
                answer: LocalizedStringResource("ANSWER_\(index)")
            )
        }
    }()
    
    
    var body: some View {
        HStack {
            Text("FAQ")
                .font(.title.bold())
            Spacer()
        }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 8)
        ForEach(Self.questions) { question in
            PAWSCard {
                VStack(alignment: .leading) {
                    HStack {
                        Text(question.question)
                            .font(.title3.bold())
                            .multilineTextAlignment(.leading)
                            .padding(.bottom, 4)
                        Spacer()
                    }
                    HStack {
                        Text(question.answer)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                }
                    .padding()
                    .frame(maxWidth: .infinity)
            }
                .padding(.vertical, 8)
        }
    }
}


#Preview {
    NavigationStack {
        ScrollView {
            FAQ()
        }
    }
}
