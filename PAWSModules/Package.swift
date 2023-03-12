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
        .library(name: "PAWSSharedContext", targets: ["PAWSSharedContext"]),
        .library(name: "PAWSLandingScreen", targets: ["PAWSLandingScreen"]),
        .library(name: "PAWSNotificationScreen", targets: ["PAWSNotificationScreen"])
    ],
    dependencies: [
        .package(url: "https://github.com/StanfordBDHG/CardinalKit.git", .upToNextMinor(from: "0.3.5")),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.5.0"),
        .package(url: "https://github.com/apple/FHIRModels.git", .upToNextMajor(from: "0.4.0"))
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
                .product(name: "FHIR", package: "CardinalKit"),
                .product(name: "FirebaseAccount", package: "CardinalKit"),
                .product(name: "FirestoreDataStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreSwift", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "ModelsR4", package: "fhirmodels")
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
                .product(name: "FirebaseAccount", package: "CardinalKit"),
                .product(name: "HealthKitDataSource", package: "CardinalKit"),
                .product(name: "Onboarding", package: "CardinalKit")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "PAWSSharedContext"
        ),
        .target(
            name: "PAWSLandingScreen"
        ),
        .target(
            name: "PAWSNotificationScreen"
        )
    ]
)
