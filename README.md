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
