//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziHealthKit


extension HealthKitQueryTimeRange {
    /// The time range since a specific date until now.
    static func since(_ date: Date) -> Self {
        guard date <= .now else {
            assertionFailure("Date passed into the .since() HealthKitQueryTimeRange should be in the past.")
            // We still provide a best-effort appraoch in a release build.
            return .init((.now)...(.now))
        }
        
        return .init(date...(.now))
    }
}
