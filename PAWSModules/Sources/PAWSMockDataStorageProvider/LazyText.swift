//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI
import HealthKitOnFHIR

struct LazyText: View {
    private let text: String
    @State private var lines: [(linenumber: Int, text: String)] = []
    
    
    var body: some View {
        LazyVStack(alignment: .leading) {
            ForEach(lines, id: \.linenumber) { line in
                Text(line.text)
                    .multilineTextAlignment(.leading)
            }
        }
            .onAppear {
                var lineNumber = 0
                text.enumerateLines { line, _ in
                    lines.append((lineNumber, line))
                    lineNumber += 1
                }
            }
    }
    
    
    init(text: String) {
        self.text = text
    }
}

struct LazyText_Previews: PreviewProvider {
    
    static var previews: some View {
  //      let mapping = Bundle.main.ecgTracing(withName: "ECGSample")
        let mapping = "Pizza party"
        LazyText(text: String(describing: mapping))
    }
}

