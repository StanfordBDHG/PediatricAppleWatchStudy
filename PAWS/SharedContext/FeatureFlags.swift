//
// This source file is part of the PAWS application based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

/// A collection of feature flags for the PAWS.
enum FeatureFlags {
    /// Skips the onboarding flow to enable easier development of features in the application and to allow UI tests to skip the onboarding flow.
    static let skipOnboarding = CommandLine.arguments.contains("--skipOnboarding")
    /// Always show the onboarding when the application is launched. Makes it easy to modify and test the onboarding flow without the need to manually remove the application or reset the simulator.
    static let showOnboarding = CommandLine.arguments.contains("--showOnboarding")
    /// Disables the Firebase interactions, including the login/sign-up step and the Firebase Firestore upload.
    static let disableFirebase = CommandLine.arguments.contains("--disableFirebase")
    #if targetEnvironment(simulator)
    /// Defines if the application should connect to the local firebase emulator. Always set to true when using the iOS simulator.
    static let useFirebaseEmulator = true
    #else
    /// Defines if the application should connect to the local firebase emulator. Always set to true when using the iOS simulator.
    static let useFirebaseEmulator = CommandLine.arguments.contains("--useFirebaseEmulator")
    #endif
    // add a flag for screenshot stuff
    // one test that creates three ECGs in health app, then passes in flag for go through onboarding, take some screenshots, and then exit the test
    // only put assertions that you're on the desired screen; then take a screenshot
    // actually make it part of the existing UI tests, trigger them at the right points
    // after all the tests you can add some more ECGs and then take a screenshot
    // does firebase pass in screenshot mode vairable
    // look at fastlane snapshot docs for the GitHub Actions integration stuff
}
