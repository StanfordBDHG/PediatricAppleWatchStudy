#
# This source file is part of the Stanford Spezi open-source project
#
# SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#

"""
Classes and functions specific to support the review process for the ECG recordings in
the PediatricAppleWatchStudy.
"""

# Standard library imports
from datetime import datetime

# Related third-party imports
import math
import numpy as np
import pandas as pd
import csv
from google.cloud.firestore import Client
from google.cloud.firestore_v1.base_query import FieldFilter

# Local application/library specific imports
from spezi_data_pipeline.data_access.firebase_fhir_data_access import (
    FirebaseFHIRAccess,
    get_code_mappings,
)
from spezi_data_pipeline.data_flattening.fhir_resources_flattener import ColumnNames

USERS_COLLECTION = "users"
ECG_DATA_SUBCOLLECTION = "HealthKit"
DIAGNOSIS_DATA_SUBCOLLECTION = "Diagnosis"
DEFAULT_TIMEOUT = getattr(FirebaseFHIRAccess, "DEFAULT_TIMEOUT", 60.0)


class ColumnMismatchError(Exception):
    """
    Exception raised for errors in the column structure.

    This error is raised when there is a mismatch in the expected and actual
    number of columns or column names in a dataset.

    Attributes:
        message (str): Explanation of the error.
    """

    def __init__(self, message="Column mismatch error"):
        self.message = message
        super().__init__(self.message)


def process_ecg_data(
    db: Client,
    data: pd.DataFrame,
    timeout: float = DEFAULT_TIMEOUT,
) -> pd.DataFrame:
    """
    Prepare ECG data by fetching diagnosis data, creating a diagnosis dataframe,
    concatenating it with the provided dataframe, splitting the ECG recordings into
    10-second parts, and prioritizing abnormal recordings.

    Args:
        db (Client): Firestore database client.
        flattened_df (pd.DataFrame): Flattened DataFrame with ECG data.
        timeout (float): Timeout in seconds for Firestore stream operations.

    Returns:
        pd.DataFrame: Processed ECG data.
    """

    # Get diagnosis-related data from Firestore
    data_diagnosis_enhanced = fetch_diagnosis_data(db, data, timeout=timeout)

    # Split the 30-sec ECG recording into 10-sec parts for better visualization
    data_after_splits = split_ecg_recording_in_10sec_parts(data_diagnosis_enhanced)

    # Get the user information data from Firestore and store it in pd.DataFrame format
    users_data = fetch_users_list(db, timeout=timeout)

    # Add the user information data to the processed data
    data_diagnosis_users_enhanced = merge_dataframes_on_userid(
        data_after_splits, users_data
    )

    # Add a column based on the user's age
    data_diagnosis_users_enhanced_age = add_age_group_column(
        data_diagnosis_users_enhanced
    )

    processed_data = prioritize_abnormal_recordings(data_diagnosis_users_enhanced_age)

    return processed_data


def fetch_symptoms_single(observation_data: dict) -> dict:
    """
    Extracts symptoms information from a single observation data dictionary and
    returns a dict with a normalized Symptoms field.

    Args:
        observation_data: A dictionary containing observation data.

    Returns:
        dict: A dictionary with 'UserId', 'ResourceId', and 'Symptoms'.
    """
    components = observation_data.get("component", [])
    user_id = observation_data.get(ColumnNames.USER_ID.value)
    resource_id = observation_data.get("ResourceId")

    symptoms_status = None
    for comp in components:
        code = comp.get("code", {}).get("coding", [{}])[0].get("code")
        if code == "HKElectrocardiogram.SymptomsStatus":
            symptoms_status = comp.get("valueString")
            break

    symptoms_text = "No symptoms."
    if symptoms_status == "present":
        symptoms_list = []
        for comp in components:
            code = comp.get("code", {}).get("coding", [{}])[0].get("code", "")
            if "HKCategoryTypeIdentifier" in code:
                display = comp.get("code", {}).get("coding", [{}])[0].get("display")
                value = comp.get("valueString")
                if display and value is not None:
                    symptoms_list.append(f"{display}:{value}")
        if symptoms_list:
            symptoms_text = ", ".join(symptoms_list)

    return {
        ColumnNames.USER_ID.value: user_id,
        "ResourceId": resource_id,
        "Symptoms": symptoms_text,
    }


def fetch_diagnosis_data(  # pylint: disable=too-many-locals, too-many-branches, too-many-nested-blocks
    db: Client,
    input_df: pd.DataFrame,
    collection_name=USERS_COLLECTION,
    subcollection_name=ECG_DATA_SUBCOLLECTION,
    timeout: float = DEFAULT_TIMEOUT,
) -> pd.DataFrame:
    """
    Fetch diagnosis data from the Firestore database and extend the input DataFrame with new
    columns.

    Args:
        db (Client): Firestore database client.
        input_df (pd.DataFrame): Input DataFrame to be extended.
        collection_name (str, optional): Name of the main collection. Defaults to USERS_COLLECTION.
        subcollection_name (str, optional): Name of the subcollection. Defaults to
            ECG_DATA_SUBCOLLECTION.
        timeout (float): Timeout in seconds for Firestore stream operations.

    Returns:
        pd.DataFrame: Extended DataFrame containing the fetched diagnosis data.
    """
    collection_ref = db.collection(collection_name)
    resources = []
    new_columns = set()

    for user_doc in collection_ref.stream(
        timeout=timeout
    ):  # pylint: disable=too-many-nested-blocks
        try:
            user_id = user_doc.id
            query = (
                db.collection(collection_name)
                .document(user_id)
                .collection(subcollection_name)
            )

            display_str, code_str, system_str = get_code_mappings("131328")

            fhir_docs = query.where(
                filter=FieldFilter(
                    "code.coding",
                    "array_contains",
                    {"display": display_str, "system": system_str, "code": code_str},
                )
            ).stream(timeout=timeout)

            for doc in fhir_docs:
                observation_data = doc.to_dict()
                observation_data["user_id"] = user_id
                observation_data[ColumnNames.USER_ID.value] = user_id
                observation_data["ResourceId"] = doc.id
                observation_data[ColumnNames.RESOURCE_ID.value] = doc.id
                diagnosis_docs = list(
                    doc.reference.collection(DIAGNOSIS_DATA_SUBCOLLECTION).stream(
                        timeout=timeout
                    )
                )

                if diagnosis_docs:
                    physician_initials_list = [
                        diagnosis_doc.to_dict().get("physicianInitials")
                        for diagnosis_doc in diagnosis_docs
                        if diagnosis_doc.to_dict().get("physicianInitials")
                    ]
                    observation_data["NumberOfReviewers"] = len(physician_initials_list)
                    observation_data["Reviewers"] = physician_initials_list
                else:
                    observation_data["NumberOfReviewers"] = 0
                    observation_data["Reviewers"] = []

                observation_data["ReviewStatus"] = (
                    "Incomplete review"
                    if observation_data["NumberOfReviewers"] < 3
                    else "Complete review"
                )

                symptoms_info = fetch_symptoms_single(observation_data)
                if symptoms_info:
                    observation_data.update(symptoms_info)
                resources.append(observation_data)

                for i, diagnosis_doc in enumerate(diagnosis_docs):
                    if diagnosis_doc:
                        doc_data = diagnosis_doc.to_dict()
                        for key, value in doc_data.items():
                            col_name = f"Diagnosis{i+1}_{key}"
                            new_columns.add(col_name)
                            observation_data[col_name] = value

        except Exception as e:  # pylint: disable=broad-exception-caught
            print(f"An error occurred while processing user {user_id}: {str(e)}")

    columns = [
        ColumnNames.USER_ID.value,
        "ResourceId",
        "EffectiveDateTimeHHMM",
        ColumnNames.APPLE_ELECTROCARDIOGRAM_CLASSIFICATION.value,
        "NumberOfReviewers",
        "Reviewers",
        "ReviewStatus",
        "Symptoms",
    ] + list(new_columns)

    data = []

    for resource in resources:
        row_data = [
            resource.get(ColumnNames.USER_ID.value, None),
            resource.get("ResourceId", None),
            (
                resource.get("effectivePeriod", {}).get("start", None)
                if resource.get("effectivePeriod")
                else None
            ),
            (
                resource.get("component", [{}])[2].get("valueString", None)
                if len(resource.get("component", [])) > 2
                else None
            ),
            resource.get("NumberOfReviewers", None),
            resource.get("Reviewers", None),
            resource.get("ReviewStatus", None),
            resource.get("Symptoms", None),
        ]
        for col in new_columns:
            row_data.append(resource.get(col, None))

        data.append(row_data)

    fetched_df = pd.DataFrame(data, columns=columns)

    # Extend the input_df with new columns based on ResourceId
    extended_df = input_df.copy()
    additional_columns = [
        "ResourceId",
        "NumberOfReviewers",
        "Reviewers",
        "ReviewStatus",
        "EffectiveDateTimeHHMM",
        "Symptoms",
    ] + list(new_columns)

    for col in additional_columns:
        if col not in extended_df.columns:
            extended_df[col] = None

    for index, row in extended_df.iterrows():
        resource_id = row["ResourceId"]
        fetched_row = fetched_df[fetched_df["ResourceId"] == resource_id]
        if not fetched_row.empty:
            for col in additional_columns:
                if col in fetched_row.columns:
                    extended_df.at[index, col] = fetched_row[col].values[0]

    return extended_df


def convert_string_to_list_of_floats(s: str) -> list[float]:
    """
    Convert a string to a list of floats.

    Args:
        s (str): Input string.

    Returns:
        List[float]: List of floats.

    Raises:
        ValueError: If any part of the string cannot be converted to a float.
        TypeError: If the input is not a string.
    """
    if not isinstance(s, str):
        raise TypeError("Input must be a string.")
    try:
        return [float(item) for item in s.split()]
    except ValueError as e:
        raise ValueError(f"Error converting string to floats: {e}") from e


def divide_list_by_1000(float_list):
    """Divide all elements in a list by 1000."""
    return [x / 1000 for x in float_list]


def split_ecg_recording_in_10sec_parts(df: pd.DataFrame) -> pd.DataFrame:
    """
    Split ECG recordings into three parts of 10 seconds each.

    Args:
        df (pd.DataFrame): DataFrame with ECG data.

    Returns:
        pd.DataFrame: DataFrame with split ECG recordings.
    """
    df["ECGRecording"] = (
        df["ECGRecording"]
        .apply(convert_string_to_list_of_floats)
        .apply(divide_list_by_1000)
    )

    df[ColumnNames.SAMPLING_FREQUENCY.value] = df[
        ColumnNames.SAMPLING_FREQUENCY.value
    ].astype(float)

    def split_into_three_parts(recording, sampling_frequency):
        samples_per_10s = int(sampling_frequency * 10)

        part1 = recording[:samples_per_10s] + [np.nan] * (
            samples_per_10s - len(recording[:samples_per_10s])
        )
        part2 = recording[samples_per_10s : samples_per_10s * 2] + [np.nan] * (
            samples_per_10s - len(recording[samples_per_10s : samples_per_10s * 2])
        )
        part3 = recording[samples_per_10s * 2 : samples_per_10s * 3] + [np.nan] * (
            samples_per_10s - len(recording[samples_per_10s * 2 : samples_per_10s * 3])
        )

        return part1, part2, part3

    df[["ECGDataRecording1", "ECGDataRecording2", "ECGDataRecording3"]] = df.apply(
        lambda row: pd.Series(
            split_into_three_parts(
                row[ColumnNames.ECG_RECORDING.value],
                row[ColumnNames.SAMPLING_FREQUENCY.value],
            )
        ),
        axis=1,
    )

    return df


def prioritize_abnormal_recordings(df: pd.DataFrame) -> pd.DataFrame:
    """
    Prioritize abnormal ECG recordings by placing them at the top of the DataFrame.

    Args:
        df (pd.DataFrame): DataFrame with ECG data.

    Returns:
        pd.DataFrame: Sorted DataFrame with abnormal recordings at the top.
    """
    df["Priority"] = (
        df[ColumnNames.APPLE_ELECTROCARDIOGRAM_CLASSIFICATION.value] != "sinusRhythm"
    ).astype(int)

    sorted_df = df.sort_values(by="Priority", ascending=False)
    sorted_df = sorted_df.drop(columns=["Priority"])
    return sorted_df


def fetch_users_list(
    db: Client,
    collection_name: str = USERS_COLLECTION,
    timeout: float = DEFAULT_TIMEOUT,
) -> pd.DataFrame:
    """
    Fetches the list of users from the Firestore database and returns it as a DataFrame.

    Parameters:
    db : Firestore client object
        The Firestore client object used to access the database.
    collection_name : str, optional
        The name of the Firestore collection containing user data (default is USERS_COLLECTION).
    timeout : float, optional
        Timeout in seconds for Firestore stream operations.

    Returns:
    pd.DataFrame
        DataFrame containing user data with user IDs as one of the columns.
    """
    users = db.collection(collection_name).stream(timeout=timeout)
    users_data = []
    all_identifiers: set[str] = set()

    for user in users:
        user_data = user.to_dict()
        if user_data:
            user_data[ColumnNames.USER_ID.value] = user.id
            users_data.append(user_data)
            all_identifiers.update(user_data.keys())

    df = pd.DataFrame(users_data)

    for identifier in all_identifiers:
        if identifier not in df.columns:
            df[identifier] = None

    column_order = [ColumnNames.USER_ID.value] + [
        col for col in df.columns if col != ColumnNames.USER_ID.value
    ]
    df = df[column_order]

    return df


def merge_dataframes_on_userid(df1: pd.DataFrame, df2: pd.DataFrame) -> pd.DataFrame:
    """
    Merges two DataFrames on 'UserId' and reorders the columns.

    Parameters:
    df1 : pd.DataFrame
        The first DataFrame with a 'UserId' column.
    df2 : pd.DataFrame
        The second DataFrame with a 'UserId' column.

    Returns:
    pd.DataFrame
        A merged DataFrame with columns reordered.
    """
    merged_df = pd.merge(df1, df2, on=ColumnNames.USER_ID.value, how="left")

    df1_cols = [col for col in df1.columns if col != ColumnNames.USER_ID.value]
    df2_cols = [col for col in df2.columns if col != ColumnNames.USER_ID.value]

    reordered_columns = [ColumnNames.USER_ID.value] + df2_cols + df1_cols
    merged_df = merged_df[reordered_columns]

    return merged_df


def export_database_in_csv(
    data: pd.DataFrame,
    filename: str = "database",
    chunk_size: int | None = None,
) -> tuple[pd.DataFrame, list[str]] | pd.DataFrame:
    """
    Export data to CSV. If chunk_size is provided, export multiple CSVs each with
    up to chunk_size rows.

    Args:
        data: Input DataFrame.
        filename: Base filename (without timestamp/extension).
        chunk_size: If None, export a single CSV. If int, export chunked CSVs.

    Returns:
        - If chunk_size is None: output_database (pd.DataFrame)
        - If chunk_size is set: (output_database, written_files)
    """
    if chunk_size is not None and chunk_size <= 0:
        raise ValueError("chunk_size must be a positive integer or None.")

    datetime_str = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

    output_database = add_age_group_column(data.copy())
    total_rows = len(output_database)
    print(f"Total rows: {total_rows}")

    # Single file (backward-compatible behavior)
    if chunk_size is None:
        out = f"{filename}_{datetime_str}.csv"
        output_database.to_csv(
            out,
            index=False,
            encoding="utf-8",
            quoting=csv.QUOTE_MINIMAL,
            escapechar="\\",
            lineterminator="\n",
        )
        return output_database

    # Chunked export
    num_chunks = math.ceil(total_rows / chunk_size)
    written_files: list[str] = []
    print(f"Number of chunks: {num_chunks} (chunk_size={chunk_size})")

    for i in range(num_chunks):
        start = i * chunk_size
        end = min(start + chunk_size, total_rows)

        chunk_df = output_database.iloc[start:end].copy()

        text_cols = [c for c in chunk_df.columns if chunk_df[c].dtype == "object"]
        for c in text_cols:
            chunk_df[c] = chunk_df[c].apply(
                lambda x: x.replace("\r\n", " ").replace("\n", " ").replace("\r", " ")
                if isinstance(x, str) else x
            )

        out = f"{filename}_part_{i+1:04d}_{datetime_str}.csv"
        chunk_df.to_csv(
            out,
            index=False,
            encoding="utf-8",
            quoting=csv.QUOTE_MINIMAL,
            escapechar="\\",
            lineterminator="\n",
        )
        written_files.append(out)

    return output_database, written_files


def add_age_group_column(users_df: pd.DataFrame) -> pd.DataFrame:
    """
    Add a column "AgeGroup" to the DataFrame based on the users' ages.

    Args:
        users_df (pd.DataFrame): DataFrame containing user information with
            a 'DateOfBirthKey' column.

    Returns:
        pd.DataFrame: DataFrame with an added "AgeGroup" column.
    """

    def determine_age_group(birthdate):
        if isinstance(birthdate, pd.Timestamp):
            birthdate = birthdate.strftime("%Y-%m-%d")
        birthdate = datetime.strptime(birthdate, "%Y-%m-%d")
        current_date = datetime.now()
        age = (current_date - birthdate).days // 365
        return "Adult" if age > 18 else "Child"

    users_df["AgeGroup"] = users_df["DateOfBirthKey"].apply(determine_age_group)
    return users_df
