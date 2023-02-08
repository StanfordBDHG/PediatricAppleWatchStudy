//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FHIR
import HealthKitOnFHIR
import Foundation


extension Foundation.Bundle {
    func ecgTracing(withName name: String) -> HKElectrocardiogramMapping {
        guard let resourceURL = self.url(forResource: name, withExtension: "json") else {
            print(self.bundleURL)
            fatalError("Could not find the ecgTracing \"\(name)\".json in Bundle.")
        }
        
        do {
            let resourceData: Data = name.data(using: .utf8)!
            return try JSONDecoder().decode(HKElectrocardiogramMapping.self, from: resourceData)
        } catch {
            fatalError("Could not decode the FHIR ecgTracing named \"\(name).json\": \(error)")
        }
    }
}
