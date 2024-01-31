//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// The context attached to each task in the PAWS app.
enum PAWSTaskContext: Codable {
    /// Reminder Notificaiton to do a ECG recording
    case reminder
}
