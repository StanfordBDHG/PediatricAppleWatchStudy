//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziScheduler


extension Scheduler {
    func scheduleReminders(time: DateComponents) async throws {
        // We discard all other date components:
        let hours = time.hour.map({ [$0] }) ?? []
        let minutes = time.minute.map({ [$0] }) ?? []
        
        try createOrUpdateTask(
            id: "PAWS Reminder",
            title: "Friendly reminder to record your ECG!",
            instructions: "Thank you for participating in the PAWS study!",
            category: .custom("Reminder"),
            schedule: .init(
                startingAt: Calendar.current.startOfDay(for: .now),
                recurrence: .daily(calendar: .current, end: .afterOccurrences(7), hours: hours, minutes: minutes)
            )
        )
    }
}
