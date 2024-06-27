#
# This source file is part of the Stanford Spezi open-source project
#
# SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#

"""
Module for managing Firestore invitation codes by setting a 'used' field to False 
and deleting the 'usedBy' field in all documents within the 'invitationCodes' collection.

This module connects to Firestore using FirebaseFHIRAccess and performs the required 
document updates.

Functions:
    set_unused(db: Client): Sets the 'used' field to False and deletes the 'usedBy' field 
                            in all documents within the 'invitationCodes' collection.
    main(): Connects to Firestore using FirebaseFHIRAccess and updates the documents in 
            the 'invitationCodes' collection.
"""

import os
from spezi_data_pipeline.data_access.firebase_fhir_data_access import (
    FirebaseFHIRAccess,
)
from firebase_admin import firestore
from google.cloud.firestore_v1.client import Client


def set_unused(db: Client):
    """
    Sets the 'used' field to False and deletes the 'usedBy' field in all documents
    within the 'invitationCodes' collection.

    Args:
        db (Client): The Firestore client instance.

    Note:
        This function streams all documents in the 'invitationCodes' collection and
        performs the update and deletion operations on each document.
    """
    invitation_codes_collection = db.collection("invitationCodes")
    docs = invitation_codes_collection.stream()
    for doc in docs:
        doc.reference.set({"used": False}, merge=True)
        doc.reference.update(
            {"usedBy": firestore.DELETE_FIELD}  # pylint: disable=no-member
        )


def main():
    """
    Connects to Firestore using FirebaseFHIRAccess and updates the documents in the
    'invitationCodes' collection by setting the 'used' field to False and deleting the
    'usedBy' field.

    Environment Variables:
        FIRESTORE_EMULATOR_HOST (str): The Firestore emulator host (e.g., "localhost:8080").
        GCLOUD_PROJECT (str): The Google Cloud project ID.

    Note:
        Ensure that the path to the service account JSON file is adjusted as needed.
    """
    # Assuming that the following environment variables are already set:
    # export FIRESTORE_EMULATOR_HOST="localhost:8080"
    # export GCLOUD_PROJECT=<project_id>
    # Additionally, adjust the path to the service account JSON file as needed.
    firebase_access = FirebaseFHIRAccess(os.environ["GCLOUD_PROJECT"], "")
    firebase_access.connect()
    set_unused(firebase_access.db)


if __name__ == "__main__":
    main()
