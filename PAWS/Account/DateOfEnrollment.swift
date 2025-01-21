//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziAccount
import SpeziViews
import SwiftUI


// swiftlint:disable file_types_order
private struct DisplayView: DataDisplayView {
    private let value: Date

    @Environment(\.locale) private var locale

    private var formatStyle: Date.FormatStyle {
        .init()
        .locale(locale)
        .year(.defaultDigits)
        .month(locale.identifier == "en_US" ? .abbreviated : .defaultDigits)
        .day(.defaultDigits)
    }

    var body: some View {
        ListRow(AccountKeys.dateOfBirth.name) {
            Text(value.formatted(formatStyle))
        }
    }

    init(_ value: Date) {
        self.value = value
    }
}


private struct EntryView: DataEntryView {
    @Binding private var value: Date
    
    var body: some View {
        DisplayView(value)
    }

    init(_ value: Binding<Date>) {
        self._value = value
    }
}

extension AccountDetails {
    /// The date of birth of a user.
    @AccountKey(
        name: LocalizedStringResource("Date of Enrollment"),
        category: .other,
        as: Date.self,
        initial: .empty(Date()),
        displayView: DisplayView.self,
        entryView: EntryView.self
    )
    public var dateOfEnrollment: Date? // swiftlint:disable:this attributes
}


@KeyEntry(\.dateOfEnrollment)
extension AccountKeys {}
