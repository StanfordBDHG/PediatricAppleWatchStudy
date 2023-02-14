// swift-tools-version: 5.7

//
// This source file is part of the CS342 2023 PAWS Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import PackageDescription


let package = Package(
    name: "PAWSModules",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "PAWSContacts", targets: ["PAWSContacts"]),
        .library(name: "PAWSMockDataStorageProvider", targets: ["PAWSMockDataStorageProvider"]),
        .library(name: "PAWSOnboardingFlow", targets: ["PAWSOnboardingFlow"]),
        .library(name: "PAWSSchedule", targets: ["PAWSSchedule"]),
        .library(name: "PAWSSharedContext", targets: ["PAWSSharedContext"]),
        .library(name: "PAWSLandingScreen", targets: ["PAWSLandingScreen"]),
        .library(name: "PAWSNotificationScreen", targets: ["PAWSNotificationScreen"])
    ],
    dependencies: [
        .package(url: "https://github.com/StanfordBDHG/CardinalKit.git", .upToNextMinor(from: "0.2.1"))
    ],
    targets: [
        .target(
            name: "PAWSContacts",
            dependencies: [
                .target(name: "PAWSSharedContext"),
                .product(name: "Contact", package: "CardinalKit")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "PAWSMockDataStorageProvider",
            dependencies: [
                .target(name: "PAWSSharedContext"),
                .product(name: "CardinalKit", package: "CardinalKit"),
                .product(name: "FHIR", package: "CardinalKit")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "PAWSOnboardingFlow",
            dependencies: [
                .target(name: "PAWSSharedContext"),
                .product(name: "FHIR", package: "CardinalKit"),
                .product(name: "HealthKitDataSource", package: "CardinalKit"),
                .product(name: "Onboarding", package: "CardinalKit")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "PAWSSchedule",
            dependencies: [
                .target(name: "PAWSSharedContext"),
                .product(name: "FHIR", package: "CardinalKit"),
                .product(name: "Questionnaires", package: "CardinalKit"),
                .product(name: "Scheduler", package: "CardinalKit")
            ]
        ),
        .target(
            name: "PAWSSharedContext",
            dependencies: []
        ),
        .target(
            name: "PAWSLandingScreen",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "PAWSNotificationScreen",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
