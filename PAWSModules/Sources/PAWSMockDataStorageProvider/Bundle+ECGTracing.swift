//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import HealthKitOnFHIR
import ModelsR4

extension Foundation.Bundle {
    func ecgTracing(withName name: String) -> Observation {
        guard let resourceURL = self.url(forResource: name, withExtension: "json") else {
            print(self.bundleURL)
            fatalError("Could not find the ecgTracing \"\(name).json\" in Bundle.")
        }
        
        do {
            let resourceData = try Data(contentsOf: resourceURL)
            return try JSONDecoder().decode(Observation.self, from: resourceData)
        } catch {
            fatalError("Could not decode the FHIR ECG data named \"\(name).json\": \(error)")
        }
    }
}
