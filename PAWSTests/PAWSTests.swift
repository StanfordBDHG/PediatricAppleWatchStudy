//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

@testable import PAWS
import XCTest
import Firebase
import SpeziAccount


class PAWSTests: XCTestCase {
    func testAgeGroupIsAdultTrue() async throws {
        var components = DateComponents()
        components.year = 1970
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        let dateOfBirth = Calendar.current.date(from: components)
        XCTAssertNotNil(dateOfBirth)
        let ageYears = Calendar.current.dateComponents([.year], from: dateOfBirth!, to: .now).year
        XCTAssertNotNil(ageYears)
        XCTAssertTrue(ageYears! >= 18)
    }

    func testAgeGroupIsAdultFalse() async throws {
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -12, to: .now)
        XCTAssertNotNil(dateOfBirth)
        let ageYears = Calendar.current.dateComponents([.year], from: dateOfBirth!, to: .now).year
        XCTAssertNotNil(ageYears)
        XCTAssertFalse(ageYears! >= 18)
    }
}
