#
# This source file is part of the Stanford Spezi open-source project
#
# SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#


# Library Imports
from datetime import datetime
import datetime
from typing import List, Dict, Optional, Union
import pandas as pd

import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore_v1.client import Client

from .utils import *
from .firebase_access import *

        
def process_data(db: Client) -> pd.DataFrame:
    fetched_data = fetch_data(db)
    flattened_data = flatten_data(fetched_data) 
    renamed_data = rename_columns_of_flattened_df(flattened_data)
    processed_data = prioritize_abnormal_recordings(renamed_data)
    
    return processed_data
    

def flatten_data(fetched_data: List[Dict]) -> pd.DataFrame:
    flattened_list = [flatten_individual(data) for data in fetched_data]    
    return pd.DataFrame(flattened_list)



def flatten_individual(data: Dict, prefix='') -> Dict:
    """
    Recursively flatten a single nested dictionary.

    Parameters:
        data (dict): The nested dictionary to flatten.
        prefix (str): The prefix for keys during recursion.

    Returns:
        dict: A flattened dictionary.
    """
    result = {}
    for key, value in data.items():
        if isinstance(value, dict):
            result.update(flatten_individual(value, prefix=prefix + key + '.'))
        elif isinstance(value, list):
            for i, item in enumerate(value):
                if isinstance(item, dict):
                    result.update(flatten_individual(item, prefix=prefix + key + '.' + str(i) + '.'))
                else:
                    result[prefix + key + '.' + str(i)] = item
        else:
            result[prefix + key] = value
    return result


    
def rename_columns_of_flattened_df(flattened_df: pd.DataFrame):

    
    columns_with_defaults = {
        'NumberOfReviewers': 0,  
        'Reviewers': [],  
        'ReviewStatus': 'Incomplete review'
    }

    for column, default_value in columns_with_defaults.items():
        if column not in flattened_df.columns:
            if isinstance(default_value, list):
                flattened_df[column] = flattened_df.apply(lambda x: [], axis=1)
            else:
                flattened_df[column] = default_value
        
    reviewer_columns = [col for col in flattened_df.columns if col.startswith('Reviewers.')]
    if reviewer_columns:  # Check if the list is not empty
        flattened_df['Reviewers'] = flattened_df[reviewer_columns].apply(lambda row: [reviewer for reviewer in row if pd.notna(reviewer)], axis=1)
        flattened_df.drop(columns=reviewer_columns, inplace=True)

    # Select and rename specified columns
    renamed_df = flattened_df[['user_id',
                           'id', 
                           'effectivePeriod.start', 
                           'effectivePeriod.end', 
                           'component.0.valueQuantity.value', 
                           'component.1.valueQuantity.value', 
                           'component.1.valueQuantity.unit', 
                           'component.2.valueString', 
                           'component.3.valueQuantity.value', 
                           'component.3.valueQuantity.unit', 
                           'component.6.valueSampledData.origin.unit', 
                           'component.5.valueSampledData.data', 
                           'component.6.valueSampledData.data', 
                           'component.7.valueSampledData.data',
                           'NumberOfReviewers',
                           'Reviewers',
                           'ReviewStatus']].copy()

    renamed_df.columns = ['UserId', 
                      'DocumentId',
                      'EffectiveDateStart', 
                      'EffectiveDateEnd', 
                      'NumberOfMeasurements', 
                      'SamplingFrequency', 
                      'SamplingFrequencyUnit', 
                      'ElectrocardiogramClassification', 
                      'HeartRate', 
                      'HeartRateUnit', 
                      'ECGDataUnit', 
                      'ECGDataRecording1', 
                      'ECGDataRecording2', 
                      'ECGDataRecording3',
                      'NumberOfReviewers',
                      'Reviewers',
                      'ReviewStatus']

    for column in ['ECGDataRecording1', 'ECGDataRecording2', 'ECGDataRecording3']:
        renamed_df[column] = renamed_df[column].apply(convert_string_to_list_of_floats)

    columns_to_divide = ['ECGDataRecording1', 'ECGDataRecording2', 'ECGDataRecording3']
    renamed_df[columns_to_divide] = renamed_df[columns_to_divide].applymap(lambda x: [val / 1000 for val in x] if isinstance(x, list) else x)
    
    return renamed_df


def prioritize_abnormal_recordings(df):
    df['Priority'] = (df['ElectrocardiogramClassification'] != 'sinusRhythm').astype(int)
    sorted_df = df.sort_values(by='Priority', ascending=False)
    sorted_df = sorted_df.drop(columns=['Priority'])
    
    return sorted_df





