import argparse
import os
import random
import string
from typing import List
from ECGDataPipelineTemplate.Modules.firebase_access import connect_to_firebase
from google.cloud.firestore_v1.client import Client


def generate_random_alphanumeric(code_length: int) -> str:
    alphanumerics = string.ascii_letters + string.digits
    return "".join(random.choice(alphanumerics) for _ in range(code_length))


def upload_invitation_codes(db: Client, code_count: int, code_length: int, simulate: bool = False) -> List[str]:
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
    parser = argparse.ArgumentParser()
    parser.add_argument("-c", "--count", default=200, type=int, help="The number of invitation codes to generate")
    parser.add_argument("-l", "--length", default=8, type=int, help="The character length of each invitation code")
    parser.add_argument("-o", "--outfile", type=str,
                        help="Local path where a copy of the generated invitation codes may be saved")
    parser.add_argument("-d", "--dry", action="store_true", default=False,
                        help="Dry run the program (i.e., without uploading to Firestore)")
    parsed = parser.parse_args()

    # Assuming that the following environment variables are already set:
    # export FIRESTORE_EMULATOR_HOST="localhost:8080"
    # export GCLOUD_PROJECT=<project_id>
    # Additionally, adjust the path to the service account JSON file as needed.
    db = connect_to_firebase("", os.environ["GCLOUD_PROJECT"])
    codes = upload_invitation_codes(db, parsed.count, parsed.length, parsed.dry)

    if parsed.outfile:
        with open(parsed.outfile, "w+") as f:
            f.write("\n".join(codes))


if __name__ == "__main__":
    main()
