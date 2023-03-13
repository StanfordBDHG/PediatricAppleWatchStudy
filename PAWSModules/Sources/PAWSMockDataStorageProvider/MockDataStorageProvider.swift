//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import CardinalKit
import FHIR
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirestoreDataStorage
import Foundation
import HealthKitOnFHIR
import HealthKitUI

/// A data storage provider that collects all uploads and displays them in a user interface using the ``MockUploadList``.
public actor MockDataStorageProvider: DataStorageProvider, ObservableObjectProvider, ObservableObject {
    public typealias ComponentStandard = FHIR
    
    
    let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }()
    @MainActor @Published
    private (set) var mockUploads: [MockUpload] = []
    
    
    public init() { }
    
    
    public func process(_ element: DataChange<ComponentStandard.BaseType, ComponentStandard.RemovalContext>) async throws {
        switch element {
        case let .addition(element):
            let data = try encoder.encode(element)
            let json = String(decoding: data, as: UTF8.self)
            print(json)
            
            // let tracing = try JSONDecoder().decode(HKElectrocardiogramMapping.self, from: data)
            // print(tracing)
            // Bundle.module.ecgTracing(withName: json)
            // let symptoms = tracing.symptomsStatus.codings.description
            let symptoms = getSymptoms(tracing: json)
            
            _Concurrency.Task { @MainActor in
                mockUploads.insert(
                    MockUpload(
                        id: element.id.description,
                        type: .add,
                        path: ResourceProxy(with: element).resourceType.description,
                        body: json,
                        symptoms: symptoms
                    ),
                    at: 0
                )
            }
        case let .removal(removalContext):
            _Concurrency.Task { @MainActor in
                mockUploads.insert(
                    MockUpload(
                        id: removalContext.id.description,
                        type: .delete,
                        path: removalContext.resourceType.rawValue
                    ),
                    at: 0
                )
            }
        }
    }
    
    private func getSymptoms(tracing: String) -> String {
        var symptoms = ""
        
        if tracing.contains("Fatigue") {
            symptoms += "Fatigue; "
        }
        if tracing.contains("Dizziness") {
            symptoms += "Dizziness; "
        }
        if tracing.contains("Rapid") {
            symptoms += "Rapid, pounding or fluttering heartbeat; "
        }
        if tracing.contains("Skipped") {
            symptoms += "Skipped heartbeat; "
        }
        if tracing.contains("Shortness") {
            symptoms += "Shortness of breath; "
        }
        if tracing.contains("Chest tightness or pain") {
            symptoms += "Chest tightness or pain; "
        }
        if tracing.contains("Fainting") {
            symptoms += "Fainting; "
        }
        if tracing.contains("Other") {
            symptoms += "Other; "
        }
        
        return symptoms
    }
}
