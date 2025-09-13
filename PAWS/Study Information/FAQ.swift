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
    
    
    private static var questionAnswerPairs: [(question: LocalizedStringResource, answer: LocalizedStringResource)] = [
        (LocalizedStringResource.question1, LocalizedStringResource.answer1),
        (LocalizedStringResource.question2, LocalizedStringResource.answer2),
        (LocalizedStringResource.question3, LocalizedStringResource.answer3),
        (LocalizedStringResource.question4, LocalizedStringResource.answer4),
        (LocalizedStringResource.question5, LocalizedStringResource.answer5),
        (LocalizedStringResource.question6, LocalizedStringResource.answer6),
        (LocalizedStringResource.question7, LocalizedStringResource.answer7),
        (LocalizedStringResource.question8, LocalizedStringResource.answer8),
        (LocalizedStringResource.question9, LocalizedStringResource.answer9)
    ]
    
    
    private static var questions: [Question] = {
        questionAnswerPairs.map { Question(question: $0, answer: $1) }
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
