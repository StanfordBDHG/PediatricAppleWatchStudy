//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Scheduler


struct EventContext: Comparable, Identifiable {
    let event: Event
    let task: Task<PAWSTaskContext>
    
    
    var id: Event.ID {
        event.id
    }
    
    
    static func < (lhs: EventContext, rhs: EventContext) -> Bool {
        lhs.event.scheduledAt < rhs.event.scheduledAt
    }
}
