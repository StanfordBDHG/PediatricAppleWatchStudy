#
# This source file is part of the Stanford Spezi open-source project
#
# SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#


# Firebase and Google Cloud Firestore Imports

import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore_v1.client import Client

import os 
from typing import List, Dict, Optional, Union
from .utils import *

 
def connect_to_firebase(serviceAccountKey_file: str = None) -> Client:
    
    if os.getenv('CI') or "FIRESTORE_EMULATOR_HOST" in os.environ:
        project_id = "spezidatapipelinetemplate"
        os.environ["FIRESTORE_EMULATOR_HOST"] = "localhost:8080"
        os.environ["GCLOUD_PROJECT"] = project_id
        firebase_admin.initialize_app(options={'projectId': project_id})
        db = firestore.Client(project=project_id)    

    elif serviceAccountKey_file:
        
        # Check if a Firebase app has already been initialized to prevent reinitialization
        # The firebase_admin._apps is a dictionary holding initialized apps, and if it's empty, it means no app is initialized
        if not firebase_admin._apps:
            # Load your service account credentials from the specified file
            # These credentials allow your application to authenticate with Firebase
            cred = credentials.Certificate(serviceAccountKey_file)
            
            # Initialize your Firebase app with the credentials
            # This step is necessary to interact with Firebase services, including Firestore
            firebase_admin.initialize_app(cred)

        # Create a Firestore client instance
        # This object allows you to interact with your Firestore database, such as querying or updating documents
        db = firestore.client()

    return db



def fetch_data(db: Client, collection_name='users') -> List[Dict]:
    users_ref = db.collection(collection_name)
    fetched_data = []

    for user_doc in users_ref.stream():
        user_id = user_doc.id
        observations_ref = users_ref.document(user_id).collection('Observation')

        for obs_doc in observations_ref.stream():
            observation_data = obs_doc.to_dict()
            observation_data['user_id'] = user_id

            try:
                diagnosis_ref = obs_doc.reference.collection('Diagnosis')
                diagnosis_docs = diagnosis_ref.stream()
                # This list comprehension gathers all physicianInitials into a list for this observation
                physician_initials_list = [doc.to_dict().get('physicianInitials') for doc in diagnosis_docs if doc.to_dict().get('physicianInitials')]
                
                observation_data['NumberOfReviewers'] = len(physician_initials_list)
                observation_data['Reviewers'] = physician_initials_list
            except Exception as e:
                # In case of an error, defaults indicate no reviewers
                observation_data['NumberOfReviewers'] = 0
                observation_data['Reviewers'] = []

            observation_data['ReviewStatus'] = 'Incomplete review' if observation_data['NumberOfReviewers'] < 3 else 'Complete review'
            fetched_data.append(observation_data)
    
    return fetched_data




def fetch_users_list(db: Client, collection_name: str = 'users', save_as_csv: bool = False) -> pd.DataFrame:
    users = db.collection(collection_name).stream()
    users_data = []
    all_identifiers = set()

    for user in users:
        user_data = user.to_dict()
        if user_data:
            user_data['User Document ID'] = user.id
            users_data.append(user_data)
            all_identifiers.update(user_data.keys())

    df = pd.DataFrame(users_data)

    # This step is optional and depends on the need for consistency in the DataFrame's structure
    for identifier in all_identifiers:
        if identifier not in df.columns:
            df[identifier] = None

    column_order = ['User Document ID'] + [col for col in df.columns if col != 'User Document ID']
    df = df[column_order]

    if save_as_csv:
        filename = f'users_list_{datetime.now().strftime("%Y-%m-%d")}.csv'
        save_dataframe_to_csv(df, filename)

    return df

