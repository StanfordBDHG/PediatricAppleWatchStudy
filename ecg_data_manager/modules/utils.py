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
import numpy as np
import pandas as pd
from google.cloud.firestore import Client
from google.cloud.firestore_v1.base_query import FieldFilter

# Local application/library specific imports
from spezi_data_pipeline.data_access.firebase_fhir_data_access import get_code_mappings
from spezi_data_pipeline.data_flattening.fhir_resources_flattener import ColumnNames

USERS_COLLECTION = "users"
ECG_DATA_SUBCOLLECTION = "HealthKit"
DIAGNOSIS_DATA_SUBCOLLECTION = "Diagnosis"


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


def process_ecg_data(db: Client, data: pd.DataFrame) -> pd.DataFrame:
    """
    Prepare ECG data by fetching diagnosis data, creating a diagnosis dataframe,
    concatenating it with the provided dataframe, splitting the ECG recordings into
    10-second parts, and prioritizing abnormal recordings.

    Args:
        db (Client): Firestore database client.
        flattened_df (pd.DataFrame): Flattened DataFrame with ECG data.

    Returns:
        pd.DataFrame: Processed ECG data.
    """

    # Get diagnosis-related data from Firestore
    data_diagnosis_enhanced = fetch_diagnosis_data(db, data)

    # Split the 30-sec ECG recording into 10-sec parts for better visualization
    data_after_splits = split_ecg_recording_in_10sec_parts(data_diagnosis_enhanced)

    # Get the user information data from Firestore and store it in pd.DataFrame format
    users_data = fetch_users_list(db)

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
    Extracts symptoms information from the components array of a single observation data dictionary where
    HKElectrocardiogram.SymptomsStatus is 'present'. Returns 'UserId', 'ResourceId', and 'Symptoms'.
    This data is suitable for merging with a main DataFrame.

    Args:
        observation_data: A dictionary containing observation data.

    Returns:
        dict: A dictionary with 'UserId', 'ResourceId', and 'Symptoms' if symptoms are present.
              Returns an empty dictionary if no symptoms are present or if SymptomsStatus is not 'present'.
    """
    components = observation_data.get("component", [])
    user_id = observation_data.get(ColumnNames.USER_ID.value)
    resource_id = observation_data.get(ColumnNames.RESOURCE_ID.value)

    # Check for SymptomsStatus
    symptoms_status = next(
        (
            comp.get("valueString")
            for comp in components
            if comp.get("code", {}).get("coding", [{}])[0].get("code")
            == "HKElectrocardiogram.SymptomsStatus"
        ),
        None,
    )

    # If SymptomsStatus is "present", extract symptoms
    if symptoms_status == "present":
        symptoms = [
            f"{comp.get('code', {}).get('coding', [{}])[0].get('display')}:"
            f"{comp.get('valueString')}"
            for comp in components
            if "HKCategoryTypeIdentifier"
            in comp.get("code", {}).get("coding", [{}])[0].get("code", "")
        ]
        if symptoms:  # Check if symptoms list is not empty
            return {ColumnNames.USER_ID.value: user_id, ColumnNames.RESOURCE_ID.value: resource_id, "Symptoms": ', '.join(symptoms)}
        else:
            return {ColumnNames.USER_ID.value: user_id, ColumnNames.RESOURCE_ID.value: resource_id, "Symptoms": "No symptoms."}
    else:
        return {ColumnNames.USER_ID.value: user_id, ColumnNames.RESOURCE_ID.value: resource_id, "Symptoms": "No symptoms."}


def fetch_diagnosis_data(  # pylint: disable=too-many-locals, too-many-branches
    db: Client,
    input_df: pd.DataFrame,
    collection_name=USERS_COLLECTION,
    subcollection_name=ECG_DATA_SUBCOLLECTION,
) -> pd.DataFrame:
    """
    Fetch diagnosis data from the Firestore database and extend the input DataFrame with new
    columns, including a 'Symptoms' column.

    Args:
        db (Client): Firestore database client.
        input_df (pd.DataFrame): Input DataFrame to be extended.
        collection_name (str, optional): Name of the main collection. Defaults to USERS_COLLECTION.
        subcollection_name (str, optional): Name of the subcollection. Defaults to
            ECG_DATA_SUBCOLLECTION.

    Returns:
        pd.DataFrame: Extended DataFrame containing the fetched diagnosis data and symptoms.
    """
    collection_ref = db.collection(collection_name)
    resources = []
    new_columns = set()

    for user_doc in collection_ref.stream():  # pylint: disable=too-many-nested-blocks
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
            ).stream()

            # Process the FHIR documents and store observation data
            for doc in fhir_docs:
                observation_data = doc.to_dict()
                observation_data[ColumnNames.USER_ID.value] = user_id
                observation_data[ColumnNames.RESOURCE_ID.value] = doc.id

                # Extract effective period start time
                effective_start = observation_data.get('effectivePeriod', {}).get('start', '')
                if effective_start:
                    observation_data['EffectiveDateTimeHHMM'] = effective_start

                # Extract symptoms information HERE
                symptoms_info = fetch_symptoms_single(observation_data)
                if symptoms_info:
                    observation_data.update(symptoms_info)

                # Extract diagnosis information from diagnosis subcollection
                diagnosis_docs = list(
                    doc.reference.collection(DIAGNOSIS_DATA_SUBCOLLECTION).stream()
                )

                physician_initials_list = [
                    diagnosis_doc.to_dict().get("physicianInitials", "")
                    for diagnosis_doc in diagnosis_docs
                ]
                observation_data["NumberOfReviewers"] = len(physician_initials_list)
                observation_data["Reviewers"] = physician_initials_list
                observation_data["ReviewStatus"] = (
                    "Incomplete review"
                    if observation_data["NumberOfReviewers"] < 3
                    else "Complete review"
                )

                # Add new columns from diagnosis documents
                for i, diagnosis_doc in enumerate(diagnosis_docs):
                    doc_data = diagnosis_doc.to_dict()
                    for key, value in doc_data.items():
                        col_name = f"Diagnosis{i+1}_{key}"
                        new_columns.add(col_name)
                        observation_data[col_name] = value

                resources.append(observation_data)

        except Exception as e:  # pylint: disable=broad-exception-caught
            print(f"An error occurred while processing user {user_id}: {str(e)}")

    fetched_df = pd.DataFrame(resources)

    # Define columns for the final DataFrame
    columns = [
        ColumnNames.USER_ID.value,
        ColumnNames.RESOURCE_ID.value,
        "EffectiveDateTimeHHMM",
        ColumnNames.APPLE_ELECTROCARDIOGRAM_CLASSIFICATION.value,
        "NumberOfReviewers",
        "Reviewers",
        "ReviewStatus",
        "Symptoms",
    ] + list(new_columns)

    fetched_df = fetched_df.reindex(
        columns=columns, fill_value=None
    )  # Ensure columns are in order and filled

    # Extend the input DataFrame with new columns
    extended_df = input_df.copy()
    additional_columns = [
        ColumnNames.RESOURCE_ID.value,
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
        resource_id = row[ColumnNames.RESOURCE_ID.value]
        fetched_row = fetched_df[
            fetched_df[ColumnNames.RESOURCE_ID.value] == resource_id
        ]
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
    db: Client, collection_name: str = USERS_COLLECTION
) -> pd.DataFrame:
    """
    Fetches the list of users from the Firestore database and returns it as a DataFrame.

    Parameters:
    db : Firestore client object
        The Firestore client object used to access the database.
    collection_name : str, optional
        The name of the Firestore collection containing user data (default is USERS_COLLECTION).

    Returns:
    pd.DataFrame
        DataFrame containing user data with user IDs as one of the columns.
    """
    users = db.collection(collection_name).stream()
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
) -> pd.DataFrame:
    """
    Exports the processed data along with user and diagnosis details from the Firestore
    database into a CSV file.

    Parameters:
    db : Firestore client object
        The Firestore client object used to access the database.
    processed_data : pd.DataFrame
        The processed data DataFrame that needs to be merged with user and diagnosis details.
    filename : str, optional
        The base filename for the exported CSV (default is "database").


    Returns:
    pd.DataFrame
        The final merged DataFrame with user and diagnosis details.
    """

    current_datetime = datetime.now()
    datetime_str = current_datetime.strftime("%Y-%m-%d_%H-%M-%S")
    filename = f"{filename}_{datetime_str}.csv"

    output_database = add_age_group_column(data)
    output_database.to_csv(filename, index=False)


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
