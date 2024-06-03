#
# This source file is part of the Stanford Spezi open-source project
#
# SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#

import os
from ECGDataPipelineTemplate.Modules import firebase_access
from google.cloud.firestore_v1.client import Client


def set_unused(db: Client):
    invitation_codes_collection = db.collection("invitationCodes")
    docs = invitation_codes_collection.stream()
    for doc in docs:
        doc.reference.set({"used": False}, merge=True)
        doc.reference.update({"usedBy": firebase_access.firestore.DELETE_FIELD})


def main():
    # Assuming that the following environment variables are already set:
    # export FIRESTORE_EMULATOR_HOST="localhost:8080"
    # export GCLOUD_PROJECT=<project_id>
    # Additionally, adjust the path to the service account JSON file as needed.
    db = firebase_access.connect_to_firebase("", os.environ["GCLOUD_PROJECT"])
    set_unused(db)


if __name__ == "__main__":
    main()
