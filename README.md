<!--

This source file is part of the Pediatric Apple Watch Study Application based on the Stanford Spezi Template Application project

SPDX-FileCopyrightText: 2023 Stanford University

SPDX-License-Identifier: MIT

-->

# Pediatric Apple Watch Study Application

[![Deployment](https://github.com/StanfordBDHG/PediatricAppleWatchStudy/actions/workflows/deployment.yml/badge.svg)](https://github.com/StanfordBDHG/PediatricAppleWatchStudy/actions/workflows/deployment.yml)
[![codecov](https://codecov.io/gh/StanfordBDHG/PediatricAppleWatchStudy/graph/badge.svg?token=dxs74T2g0s)](https://codecov.io/gh/StanfordBDHG/PediatricAppleWatchStudy)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.10602852.svg)](https://doi.org/10.5281/zenodo.10602852)


This repository contains the Pediatric Apple Watch Study (PAWS) application.
The Pediatric Apple Watch Study Application uses the [Spezi](https://github.com/StanfordSpezi/Spezi) ecosystem and builds on top of the [Stanford Spezi Template Application](https://github.com/StanfordSpezi/SpeziTemplateApplication).


## Application Structure

The Spezi Template Application uses a modularized structure using the [Spezi modules](https://swiftpackageindex.com/StanfordSpezi) enabled by the Swift Package Manager.

The application uses the FHIR standard to provide a shared standard to encode data exchanged between different modules.

> [!NOTE]  
> Do you want to learn more about the Stanford Spezi Template Application and how to use, extend, and modify this application? Check out the [Stanford Spezi Template Application documentation](https://stanfordspezi.github.io/SpeziTemplateApplication).


## Build and Run the Application

The PAWS app uses a Google Firebase-based backend. You will need to [install the Firebase Local Emulator Suite to run a version of the service infrastructure locally](https://firebase.google.com/docs/emulator-suite/install_and_configure).
To boot up the Firebase backend, you need to run the following command to start the Firebase emulator, including a seeded version of the infrastructure. This is also required before running the automated user interface (UI) testing suite.

```bash
firebase emulators:start --import=./firebase
```

You can then visit http://127.0.0.1:4000/firestore/default/data/invitationCodes to see all the seeded invitation codes that can be used in the application. The PAWS app automatically connects to the local emulator when running in the iOS simulator using Xcode.

You can build and run the application using [Xcode](https://developer.apple.com/xcode/) by opening up the **PAWS.xcodeproj**.

## ECG Data Manager

The ECG Data Manager provides capabilities for reviewing and exploring the recorded ECG data. It relies on the [spezi_data_pipeline](https://pypi.org/project/spezi-data-pipeline/0.1.0) package, which is a library engineered to improve workflows associated with data accessibility and analysis in healthcare environments. In addition to the functions and classes of the spezi_data_pipeline, the two notebooks, namely `ECG Reviewer.ipynb` and `ECG Explorer.ipynb`, offer an environment for interactive data visualization and analysis.

The ECG Data Manager includes:
- `utils.py`: Provides utility functions for data processing.
- `visualization.py`: Contains functions for data visualization.
- `ECG Reviewer.ipynb`: An interactive notebook for loading, analyzing, and reviewing ECG data.
- `ECG Explorer.ipynb`: An interactive notebook for loading, exploring, and filtering ECG data based on filters, such as age group, ECG recording classification, user, and date.

### Notebook Setup Instructions

You can open and run the `ECG Reviewer.ipynb` and `ECG Explorer.ipynb` notebooks in, e.g., Google Colab.
Once the notebook is open, execute the following cell to clone the PediatricAppleWatchStudy repository and navigate into the cloned directory:

```bash
# Clone the repository and navigate to the ECG data manager
git clone https://github.com/StanfordBDHG/PediatricAppleWatchStudy.git
cd PediatricAppleWatchStudy/ecg_data_manager
```

To run the notebooks, add them to Colab Enterprise within the same Google Cloud project as your Firebase setup. For other Python notebook environments, use the Firebase credentials and upload the `serviceAccountKey_file.json` to the workspace directory to enable Firebase access. This file is essential for authentication and should be securely handled.

#### Use the Interactive ECG Reviewing Tool

To start reviewing ECG data, execute the cells in your notebook. 

This interactive tool allows you to plot ECG data, add diagnoses, evaluate the trace quality, and add notes.

![ecg_data_interactive_reviewer.png](ecg_data_manager/Figures/ecg_data_interactive_reviewer.png)

#### Use the Interactive ECG Exploring Tool

To start exploring ECG data, execute the cells in your notebook. 

This interactive tool allows you to plot ECG data, filter ECG recordings, and select specific users and timestamps.

![ecg_data_interactive_explorer.png](ecg_data_manager/Figures/ecg_data_interactive_explorer.png)


## Firebase & Google Cloud Setup

The Google Cloud Setup at Stanford to deploy the project requires the following setup for Google Cloud Firebase and to execute the ECG review and exploration tools.

### Firebase Setup

Each Firebase Project for `development`, `staging`, and `production` GitHub environments needs the following configurations:
- Firestore Database
- Firebase Authentication with Identity Platform (Anonymous Authentication, Username + Password, and Sign In With Apple enabled)
- Firebase Storage
- Cloud Functions (also enable Cloud Build API, Google Cloud Run, and Eventarc API)

The CI setup requires a `github-deployment@PROJECT_ID.iam.gserviceaccount.com` account that requires the following roles:
- Cloud Datastore Index Admin
- Cloud Functions Developer
- Firebase Admin
- Firebase Rules Admin
- Service Account User on PROJECT_ID@appspot.gserviceaccount.com

Set up a `cloudfunctionsserviceaccount@PROJECT_ID.iam.gserviceaccount.com` to execute cloud functions. It needs the following rules:
- Cloud Datastore User


### Generate Invitation Codes

When signing in to the application for the first time, users will be required to enter a valid invitation code before a user account is created.
Use the `upload_codes.py` script to generate new codes and upload them to a specified Firebase instance once you have deployed the firebase setup in this repository to your Firebase instance.

```bash
export FIRESTORE_EMULATOR_HOST="localhost:8080"
export GCLOUD_PROJECT=<project_id>

python -m scripts.upload_codes --outfile=<local_path> \
--count=<number_of_codes> --length=<code_length> \
--service_account=<service_account_key_file> [--dry]
```


### Notebooks & Colab Enterprise

Create a storage bucket that is used to store the packaged dependencies and code for the Python notebooks in a versioned and isolated state. You need to enable Colab Enterprise.

To secure the data in the notebook, [the network access should be restricted to needed Google services only](https://cloud.google.com/colab/docs/service-controls) and use runners that only use a private network.

Run the following commands in the `ecg_data_manager` folder to package the dependencies and upload them, as well as the `modules` folder, to the cloud storage bucket if no outside internet access is enabled.
```sh
mkdir packages
pip download -r requirements.txt -d packages
tar -czvf packages.tar.gz packages/
```

Copy the `ECG Explorer` and `ECG Reviewer` notebooks in Colab Enterprise, uncomment, and adapt the storage bucket paths if restricted network access is configured.


## Continuous Integration Setup

The project supports different GitHub environments (`development`, `staging`, and `production`).
- The Firebase project ID needs to be saved as a GitHub variable with the name `FIREBASE_PROJECT_ID` for the different deployment environments.
- The service account key needs to be added to the GitHub secrets as `GOOGLE_APPLICATION_CREDENTIALS_BASE64` in a base64 encoding to enable the beta deployment.
- To report code coverage, a CodeCov token should be added as a `CODECOV_TOKEN` environment secret.
- The Firebase Google plist needs to be stored as a base64 encoded secret named `GOOGLE_SERVICE_INFO_PLIST_BASE64`.
- Store all secrets for a beta deployment of the iOS application as documented for the [Stanford Spezi Template Application](https://github.com/StanfordSpezi/SpeziTemplateApplication).


## Generate Screenshots

PAWS uses [Fastlane Snapshots](https://docs.fastlane.tools/getting-started/ios/screenshots/) to automatically screenshot specific screens in the app during UI tests.
To generate new screenshots, you will also need to have a properly seeded local Firebase instance up and running:
```bash
firebase emulators:start --import=./firebase
```

Then, run `fastlane snapshot`.
By default, results will end up in the `.screenshots` folder, overwriting previous files.

> [!NOTE]
> Snapshot will run UI tests and concurrently take screenshots on multiple device simulators.
> As such, multiple new PAWS accounts will be created, possibly in rapid succession, using the same hard-coded testing invitation codes.

The current workaround for simultaneous account registrations during `fastlane snapshot` is to continually reset invitation codes to an unused state in Firestore by running a designated Python script on repeat (in a shell session with the same environment variables).

```bash
for i in {1..360}; do python -m scripts.upload_codes; sleep 10; done
```


## Contributing

Contributions to this project are welcome. Please make sure to read the [contribution guidelines](https://github.com/StanfordBDHG/.github/blob/main/CONTRIBUTING.md) and the [contributor covenant code of conduct](https://github.com/StanfordBDHG/.github/blob/main/CODE_OF_CONDUCT.md) first.


## License

This project is licensed under the MIT License. See [Licenses](https://github.com/StanfordBDHG/PediatricAppleWatchStudy/tree/main/LICENSES) for more information.


## Our Research

For more information, check out our website at [biodesigndigitalhealth.stanford.edu](https://biodesigndigitalhealth.stanford.edu).

![Stanford Byers Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordBDHG/.github/main/assets/biodesign-footer-light.png#gh-light-mode-only)
![Stanford Byers Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordBDHG/.github/main/assets/biodesign-footer-dark.png#gh-dark-mode-only)
