#
# This source file is part of the Stanford Spezi open-source project
#
# SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#

"""
Module for generating and uploading random alphanumeric invitation codes to Firestore.

This module includes functions to generate random alphanumeric codes, upload them to a 
Firestore collection, and handle command-line arguments for configuring the process.

Functions:
    generate_random_alphanumeric(code_length: int) -> str: Generates a random alphanumeric
                                                           string of a given length.
    upload_invitation_codes(db: Client, code_count: int, code_length: int, simulate: bool = False)
                                                   -> List[str]:  Generates and uploads invitation
                                                                  codes to Firestore.
    main(): Main function to parse command-line arguments and run the logic for generating 
            and uploading invitation codes.
"""

import argparse
import os
import random
import string
from typing import List
from spezi_data_pipeline.data_access.firebase_fhir_data_access import (
    FirebaseFHIRAccess,
)
from spezi_data_pipeline.data_flattening.fhir_resources_flattener import ENCODING
from google.cloud.firestore_v1.client import Client


def generate_random_alphanumeric(code_length: int) -> str:
    """
    Generate a random alphanumeric string.

    Args:
        code_length (int): The length of the alphanumeric string to generate.

    Returns:
        str: A randomly generated alphanumeric string of the specified length.
    """
    alphanumerics = string.ascii_letters + string.digits
    return "".join(random.choice(alphanumerics) for _ in range(code_length))


def upload_invitation_codes(
    db: Client, code_count: int, code_length: int, simulate: bool = False
) -> List[str]:
    """
    Generate and upload invitation codes to Firestore.

    Args:
        db (Client): The Firestore client instance.
        code_count (int): The number of invitation codes to generate.
        code_length (int): The character length of each invitation code.
        simulate (bool): If True, do not actually upload to Firestore (default is False).

    Returns:
        List[str]: A list of generated invitation codes.
    """
    invitation_codes_collection = db.collection("invitationCodes")
    codes = []

    for _ in range(code_count):
        code = generate_random_alphanumeric(code_length)
        if not simulate:
            document_reference = invitation_codes_collection.document(code)
            document_reference.set({"used": False})
        codes.append(code)

    return codes


def main():
    """
    Main function to parse command-line arguments and run the logic for generating
    and uploading invitation codes.

    Command-line Arguments:
        -c, --count (int): The number of invitation codes to generate (default is 200).
        -l, --length (int): The character length of each invitation code (default is 8).
        -o, --outfile (str): Local path where a copy of the generated invitation codes may be saved.
        -d, --dry (bool): Dry run the program (i.e., without uploading to Firestore) (default is
                          False).
        --service_account (str): The path to the service account JSON file for Firebase.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-c",
        "--count",
        default=200,
        type=int,
        help="The number of invitation codes to generate",
    )
    parser.add_argument(
        "-l",
        "--length",
        default=8,
        type=int,
        help="The character length of each invitation code",
    )
    parser.add_argument(
        "-o",
        "--outfile",
        type=str,
        help="Local path where a copy of the generated invitation codes may be saved",
    )
    parser.add_argument(
        "-d",
        "--dry",
        action="store_true",
        default=False,
        help="Dry run the program (i.e., without uploading to Firestore)",
    )
    parser.add_argument(
        "--service_account",
        type=str,
        help="The path to the service account JSON file for Firebase",
    )
    parsed = parser.parse_args()

    # Assuming that the following environment variables are already set:
    # export FIRESTORE_EMULATOR_HOST="localhost:8080"
    # export GCLOUD_PROJECT=<project_id>
    # Additionally, adjust the path to the service account JSON file as needed.
    firebase_access = FirebaseFHIRAccess(
        os.environ["GCLOUD_PROJECT"], parsed.service_account
    )
    firebase_access.connect()
    codes = upload_invitation_codes(
        firebase_access.db, parsed.count, parsed.length, parsed.dry
    )

    if parsed.outfile:
        with open(parsed.outfile, "w+", encoding=ENCODING) as f:
            f.write("\n".join(codes))


if __name__ == "__main__":
    main()
