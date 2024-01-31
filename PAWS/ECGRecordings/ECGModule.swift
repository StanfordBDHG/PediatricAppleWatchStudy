//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import HealthKit
import Spezi


@Observable
class ECGModule: Module, DefaultInitializable, EnvironmentAccessible {
    var hkElectrocardiograms: [HKElectrocardiogram] = []
    
    
    /// Creates an instance of a ``MockWebService``.
    required init() { }
}
