<!--

This source file is part of the CS342 2023 PAWS Team Application project

SPDX-FileCopyrightText: 2023 Stanford University

SPDX-License-Identifier: MIT

-->

# CS342 2023 PAWS Team Application

This repository contains the CS342 2023 PAWS Team Application.

It demonstrates using the [CardinalKit](https://github.com/StanfordBDHG/CardinalKit) framework template and builds on top of the [StanfordBDHG Template Application](https://github.com/StanfordBDHG/PAWS) and [StanfordBDHG CardinalKit Template Application](https://github.com/StanfordBDHG/CardinalKitPAWS).


## Application Structure

The application uses a modularized structure enabled by using the Swift Package Manager.

The application uses the CardinalKit `FHIR` standard to provide a shared repository for data exchanged between different modules using the `FHIR` standard.
You can learn more about the CardinalKit standards-based software architecture in the [CardinalKit documentation](https://github.com/StanfordBDHG/CardinalKit).


## Build and Run the Application

You can build and run the application using [Xcode](https://developer.apple.com/xcode/) by opening up the **PAWS.xcodeproj**.

The application provides a [Firebase Firestore](https://firebase.google.com/docs/firestore)-based data upload and [Firebase Authentication](https://firebase.google.com/docs/auth) login & sign-up.
It is required to have the [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite) to be up and running to use these features to build and test the application locally. Please follow the [installation instructions](https://firebase.google.com/docs/emulator-suite/install_and_configure). 

You do not have to make any modifications to the Firebase configuration, login into the `firebase` CLI using your Google account, or create a project in firebase to run, build, and test the application!

Startup the [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite) using
```
$ firebase emulators:start --only auth,firestore
```

After the emulators have started up, you can run the application in your simulator to build, test, and run the application.

The application includes the following feature flags that can be configured in the [scheme editor in Xcode](https://help.apple.com/xcode/mac/11.4/index.html?localePath=en.lproj#/dev0bee46f46) and selecting the **PAWS** scheme, the **Run** configuration, and to switch to the **Arguments** tab to add, enable, disable, or remove the following arguments passed on launch:
- ``--skipOnboarding``: Skips the onboarding flow to enable easier development of features in the application and to allow UI tests to skip the onboarding flow.
- ``--showOnboarding``: Always show the onboarding when the application is launched. Makes it easy to modify and test the onboarding flow without the need to manually remove the application or reset the simulator.
- ``--disableFirebase``: Disables the Firebase interactions, including the login/sign-up step and the Firebase Firestore upload.
- ``--useFirebaseEmulator``: Defines if the application should connect to the local firebase emulator. Always set to true when using the iOS simulator.


## Continous Delivery Workflows

The application includes continuous integration (CI) and continuous delivery (CD) setup.
- Automatically build and test the application on every pull request before deploying it.
- An automated setup to deploy the application to TestFlight every time there is a new commit on the repository's main branch.
- Ensure a coherent code style by checking the conformance to the SwiftLint rules defined in `.swiftlint.yml` on every pull request and commit.
- Ensure conformance to the [REUSE Spacification]() to property license the application and all related code.

Please refer to the [StanfordBDHG Template Application](https://github.com/StanfordBDHG/PAWS) and the [ContinousDelivery Example by Paul Schmiedmayer](https://github.com/PSchmiedmayer/ContinousDelivery) for more background about the CI and CD setup for the CardinalKit Template Application.


## Contributors & License

This project is based on [ContinousDelivery Example by Paul Schmiedmayer](https://github.com/PSchmiedmayer/ContinousDelivery), [StanfordBDHG Template Application](https://github.com/StanfordBDHG/PAWS), and the [StanfordBDHG CardinalKit Template Application](https://github.com/StanfordBDHG/CardinalKitPAWS) provided using the MIT license.
You can find a list of contributors in the `CONTRIBUTORS.md` file.

The CS342 2023 PAWS Team Application is licensed under the MIT license.
