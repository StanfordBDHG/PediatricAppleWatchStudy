//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziScheduler


/// A `Scheduler` using the ``PAWSTaskContext`` to schedule and manage tasks and events in the
/// PAWS.
typealias PAWSScheduler = Scheduler<PAWSTaskContext>


extension PAWSScheduler {
    func scheduleReminders(time: DateComponents) async throws {
        // We discard all other date components:
        let dateComponents = DateComponents(hour: time.hour, minute: time.minute)
        
        await schedule(
            task: Task(
                title: String(localized: "Friendly reminder to record your ECG!"),
                description: String(localized: "Thank you for participating in the PAWS study!"),
                schedule: Schedule(
                    start: Calendar.current.startOfDay(for: .now),
                    repetition: .matching(dateComponents),
                    end: .numberOfEvents(7)
                ),
                notifications: true,
                context: PAWSTaskContext.reminder
            )
        )
    }
}
