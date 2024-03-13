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

        guard let dateOfBirth = Calendar.current.date(from: components) else {
            XCTFail("Could not initialize date of birth.")
            return
        }
        
        guard let ageYears = Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year else {
            XCTFail("Could not calculate age.")
            return
        }
        
        XCTAssertTrue(ageYears >= 18, "Age is below 18 years.")
    }

    func testAgeGroupIsAdultFalse() async throws {
        guard let dateOfBirth = Calendar.current.date(byAdding: .year, value: -12, to: .now) else {
            XCTFail("Could not initialize date of birth.")
            return
        }
        
        guard let ageYears = Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year else {
            XCTFail("Could not calculate age.")
            return
        }
        
        XCTAssertFalse(ageYears >= 18, "Age is 18 years or older; expected younger.")
    }
}
