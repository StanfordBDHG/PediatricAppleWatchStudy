//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FHIR
import SwiftUI


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
    static let mappingJSONString = {
        let observation = Bundle.module.ecgTracing(withName: "ECGObservation")
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = (try? jsonEncoder.encode(observation)) ?? Data()
        return String(data: jsonData, encoding: .utf8) ?? ""
    }()
    static var previews: some View {
        ScrollView {
            LazyText(text: mappingJSONString)
        }
    }
}
