#
# This source file is part of the Stanford Spezi open-source project
#
# SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#


# Visualization and UI Libraries
import matplotlib.pyplot as plt
import ipywidgets as widgets
from ipywidgets import Layout
from IPython.display import display, clear_output, HTML
from matplotlib.ticker import AutoMinorLocator

# Data Handling and Scientific Computing Libraries
import pandas as pd
from pandas import to_datetime
import numpy as np
from functools import partial
from typing import List, Dict, Optional, Union
from math import ceil 
from datetime import datetime

from google.cloud.firestore_v1.client import Client
from .utils import *
from .data_preparation import *
from .firebase_access import *
        
        
class ECGDataViewer:
    def __init__(self, df_ecg, db):
        self.db = db
        self.df_ecg = df_ecg
        self.filtered_data = pd.DataFrame()
        self.plot_counter = 0
        self.ecg_output = widgets.Output()
        self.message_output = widgets.Output()
        self.setup_widgets()
        self.display_widgets()
        
    def setup_widgets(self):
        unique_initials = pd.Series(self.df_ecg['Reviewers'].explode()).dropna().astype(str).unique()
        initials_options = ['Select'] + sorted(unique_initials) + ['Other']
        self.initials_dropdown = widgets.Dropdown(options=initials_options, description='Initials:')
        self.initials_textarea = widgets.Textarea(placeholder='Enter your initials here.', description='Initials:', layout=Layout(width='300px'))
        self.initials_textarea.layout.visibility = 'hidden'
        self.initials_dropdown.observe(self.on_initials_change, names='value')

        review_statuses = ['Select'] + sorted(self.df_ecg['ReviewStatus'].dropna().unique().tolist())
        self.review_status_dropdown = widgets.Dropdown(options=review_statuses, description='Review Status:',layout=Layout(width='300px'))
        self.review_status_dropdown.style.description_width = '140px'  
        
        self.load_more_button = widgets.Button(description='LOAD MORE', button_style='info', icon='plus', layout=Layout(width='200px', height='50px'))
        self.load_more_button.on_click(self.load_more_ecg)
        self.review_status_dropdown.observe(self.update_filtered_data, names='value')

    
    def on_initials_change(self, change):
        if change['new'] == 'Other':
            self.initials_textarea.layout.visibility = 'visible'
        else:
            self.initials_textarea.layout.visibility = 'hidden'

    def display_widgets(self):
        display(self.initials_dropdown, self.initials_textarea, self.review_status_dropdown, self.ecg_output, self.message_output,self.load_more_button)

    def update_filtered_data(self, change):
        with self.ecg_output and self.message_output:
            clear_output(wait=True) 
        self.plot_counter = 0
        if change['new'] != 'Select':
            self.apply_filters()
        else:
            with self.message_output and self.ecg_output:
                clear_output(wait=True)
                print("Please select a valid review status to view ECG data.")

    def apply_filters(self):
        self.filtered_data = self.df_ecg[self.df_ecg['ReviewStatus'] == self.review_status_dropdown.value]
        self.plot_ecg_data()
        
    def plot_ecg_data(self):
        with self.ecg_output:
            clear_output(wait=True)
            onscreen_plots = 2
            for index, row in self.filtered_data.iloc[self.plot_counter:self.plot_counter+onscreen_plots].iterrows():
                self.plot_single_ecg(row)
                self.create_diagnosis_widgets(row['UserId'], row['DocumentId'])
            self.plot_counter += onscreen_plots

    def plot_single_ecg(self, row):
        fig, axs = plt.subplots(3, 1, figsize=(14, 5), constrained_layout=True)
        
        for i, key in enumerate(['ECGDataRecording1', 'ECGDataRecording2', 'ECGDataRecording3']):
            title = f"ECG part {i+1} recorded on {row['EffectiveDateStart']}"
            plotSingleLeadECG(row[key], sample_rate=row['SamplingFrequency'], title=title, ax=axs[i])
        
        user_id = row['UserId']
        heart_rate = int(row['HeartRate'])
        ecg_interpretation = row['ElectrocardiogramClassification']

        user_id_html = widgets.HTML(value=f"<b style='font-size: larger;'>User ID {user_id}</b>")
        heart_rate_html = widgets.HTML(value=f"<b style='font-size: larger;'>Average HR: {heart_rate} bpm</b>")
        interpretation_html = widgets.HTML(value=f"<b style='font-size: larger;'>Classification: ")

        # Conditional color for non-sinusRhythm classifications
        if ecg_interpretation != 'sinusRhythm':
            interpretation_html.value += f"<span style='color: red;'>{ecg_interpretation}</span>"
        else:
            interpretation_html.value += f"{ecg_interpretation}"

        interpretation_html.value += "</b>"

        display(user_id_html, heart_rate_html, interpretation_html)
        
        # Add review status
        diagnosis_collection_ref = self.db.collection('users').document(user_id).collection('Observation').document(row['DocumentId']).collection('Diagnosis')
        diagnosis_docs = list(diagnosis_collection_ref.stream())
        num_diagnosis_docs = len(diagnosis_docs)

        diagnosis_status_html = widgets.HTML(value=f"<b style='font-size: larger;'>This recording has been reviewed {num_diagnosis_docs} times:</b>")
        display(diagnosis_status_html)

        if num_diagnosis_docs != 0:
            for doc in diagnosis_docs:
                doc_data = doc.to_dict()
                physician_initial = doc_data.get('physicianInitials', 'N/A')
                diagnosis_date = doc_data.get('diagnosisDate', 'N/A')
                reviewers_html = widgets.HTML(value=f"<span style='font-size: larger;'>Physician: {physician_initial}, Date: {diagnosis_date}</span>")
                display(reviewers_html)
                
        plt.show()
        
        
    def create_diagnosis_widgets(self, user_id, document_id):
        message_output_specific = widgets.Output()  # Create a specific output for this set of widgets

        diagnosis_dropdown = widgets.Dropdown(
            options=['Select', 'Normal', 'Sinus tachycardia', 'SVT', 'EAT', 'AF', 'VT', 'Heart Block', 'Other'],
            description='Diagnosis:'
        )
        diagnosis_dropdown.style.description_width = '120px'  
        
        tracing_quality_dropdown = widgets.Dropdown(
            options=['Select', 'Uninterpretable', 'Poor quality', 'Adequate', 'Good', 'Excellent'],
            description='Tracing Quality:'
        )
        tracing_quality_dropdown.style.description_width = '140px'
        
        notes_textarea = widgets.Textarea(description='Notes:')
        save_button = widgets.Button(description='Save Diagnosis', button_style='success', icon='save', layout=Layout(width='250px', height='50px'))
        
        def hide_widgets(b):
            save_button.on_click(partial(self.save_diagnosis, user_id, document_id, diagnosis_dropdown, tracing_quality_dropdown, notes_textarea, message_output_specific))

            # Hide the widgets if not all selections have been made
            initials = self.initials_dropdown.value if self.initials_dropdown.value != 'Other' else self.initials_textarea.value.strip()
            if not (diagnosis_dropdown.value == 'Select' or tracing_quality_dropdown.value == 'Select' or initials == 'Select'):
                diagnosis_dropdown.layout.visibility = 'hidden'
                tracing_quality_dropdown.layout.visibility = 'hidden'
                notes_textarea.layout.visibility = 'hidden'
    
        # Attach the hide_widgets function to the button's on_click event
        save_button.on_click(lambda b: hide_widgets(b))
        
        # Display the widgets
        widgets_box = widgets.VBox([diagnosis_dropdown, tracing_quality_dropdown, notes_textarea, save_button, message_output_specific])
        display(widgets_box)

        # Optional: Return the widgets_box if you need to manipulate or display it elsewhere
        return widgets_box

    def load_more_ecg(self, b=None):
        with self.message_output:
            clear_output(wait=True) 
        if self.plot_counter < len(self.filtered_data):
            self.plot_ecg_data()
        else:
            with self.message_output:
                no_more_ecg_html = widgets.HTML(value=f"<b style='color: #006400; font-size: 25px;'>No more ECG data to review.✓</b>")
                display(no_more_ecg_html) 
                # print("No more ECG data to review.")

    def save_diagnosis(self, user_id, document_id, diagnosis_dropdown, tracing_quality_dropdown, notes_textarea, message_output_specific, b=None):
        with message_output_specific:
            clear_output(wait=True)
            diagnosis = diagnosis_dropdown.value
            tracing_quality = tracing_quality_dropdown.value
            notes = notes_textarea.value
            initials = self.initials_dropdown.value if self.initials_dropdown.value != 'Other' else self.initials_textarea.value.strip()

            if diagnosis == 'Select' or tracing_quality == 'Select' or initials == 'Select':
                # print('Complete all fields before saving.')
                missing_fields_html = widgets.HTML(value=f"<span style='color: red; font-size: 20px;'>Complete all fields before saving.</span>")
                display(missing_fields_html) 
                                
                return
            
            user_ref = self.db.collection('users').document(user_id)
            recording_ref = user_ref.collection('Observation').document(document_id)
            diagnosis_ref = recording_ref.collection('Diagnosis')
            num_diagnosis_docs = len(list(diagnosis_ref.stream()))
                
            new_diagnosis_data = {
                'physicianInitials': initials,
                'physicianDiagnosis': diagnosis,
                'tracingQuality': tracing_quality,
                'notes': notes,
                'diagnosisDate': datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
            }

            try:
                if num_diagnosis_docs < 3:
                    diagnosis_doc_ref = diagnosis_ref.document()
                    diagnosis_doc_ref.set(new_diagnosis_data)

                    # Update the ecg_df using the document_id as index
                    index = self.df_ecg.index[self.df_ecg['DocumentId'] == document_id].tolist()
                    if index:
                        for idx in index:
                            if idx in self.df_ecg.index:
                                self.df_ecg.at[idx, 'NumberOfReviewers'] += 1
                                if isinstance(self.df_ecg.at[idx, 'Reviewers'], list):
                                    self.df_ecg.at[idx, 'Reviewers'].append(initials)
                                    self.df_ecg.at[idx, 'ReviewStatus'] = 'Incomplete review' if self.df_ecg.at[idx, 'NumberOfReviewers']< 3 else 'Complete review'

                    # print('Diagnosis saved successfully.')
                    data_saved_html = widgets.HTML(value=f"<span style='color: green; font-size: 20px;'>Diagnosis saved successfully.✓</span>")
                    display(data_saved_html) 
                    
                    
                else:
                    print('ECG has already been reviewed. No further review is required.')
                    
            except Exception as e:
                print(f'Error saving diagnosis: {e}')
                
                
def _ax_plot(ax, x, y, secs=10, lwidth=0.5, amplitude_ecg = 1.8, time_ticks =0.2):
    ax.set_xticks(np.arange(0,secs + time_ticks,time_ticks))    
    ax.set_yticks(np.arange(-ceil(amplitude_ecg),ceil(amplitude_ecg),1.0))

    ax.minorticks_on()
    ax.xaxis.set_minor_locator(AutoMinorLocator(5))
    ax.set_ylim(-amplitude_ecg, amplitude_ecg)
    ax.set_xlim(0, secs)

    ax.grid(which='major', linestyle='-', linewidth='0.5', color='red')
    ax.grid(which='minor', linestyle='-', linewidth='0.5', color=(1, 0.7, 0.7))
    
    ax.plot(x,y, linewidth=lwidth)


def plotSingleLeadECG(
    ecg: Union[list, np.ndarray], 
    sample_rate: int = 500, 
    title: str = 'ECG', 
    fig_width: float = 15, 
    fig_height: float = 2, 
    line_w: float = 0.5, 
    ecg_amp: float = 1.8, 
    timetick: float = 0.2, 
    ax: Optional[plt.Axes] = None
) -> None:
    """Plot multi lead ECG chart.
    # Arguments
        ecg        : m x n ECG signal data, which m is number of leads and n is length of signal.
        sample_rate: Sample rate of the signal.
        title      : Title which will be shown on top off chart
        fig_width  : The width of the plot
        fig_height : The height of the plot
    """

    if not isinstance(ecg, (list, np.ndarray)):
        print(f"Invalid ECG data format for plotting: {title}")
        return

    if ax is None:
        plt.figure(figsize=(fig_width,fig_height))
        ax = plt.gca()
    
    ax.set_title(title)
    ax.set_ylabel('mV')
    ax.set_xlabel('sec')
    # plt.subplots_adjust(
    #     hspace = 0, 
    #     wspace = 0.04,
    #     left   = 0.04,  # the left side of the subplots of the figure
    #     right  = 0.98,  # the right side of the subplots of the figure
    #     bottom = 0.2,   # the bottom of the subplots of the figure
    #     top    = 0.88
    #     )
    seconds = len(ecg)/sample_rate

    # ax = plt.subplot(1, 1, 1)
    #plt.rcParams['lines.linewidth'] = 5
    step = 1.0/sample_rate
    _ax_plot(ax,np.arange(0,len(ecg)*step,step),ecg, seconds, line_w, ecg_amp, timetick)

DEFAULT_PATH = './'
show_counter = 1
def show_svg(tmp_path = DEFAULT_PATH):
    """Plot multi lead ECG chart.
    # Arguments
        tmp_path: path for temporary saving the result svg file
    """ 
    global show_counter
    file_name = tmp_path + "show_tmp_file_{}.svg".format(show_counter)
    plt.savefig(file_name)
    os.system("open {}".format(file_name))
    show_counter += 1
    plt.close()

def show():
    plt.show()

    


def exploreECGdata(df_ecg: pd.DataFrame, db: Client) -> None:
    ecg_data = df_ecg.to_dict(orient='records')

    unique_initials = pd.Series(df_ecg['Reviewers'].explode()).dropna().astype(str).unique()
    initials = (['Select'] + sorted(unique_initials) + ['Other']) if unique_initials.size > 0 else ['Select', 'SRC', 'AZ', 'VB', 'Other']
    initials_dropdown = widgets.Dropdown(options=initials, description='Select your initials:', style={'description_width': 'initial'})

    # Textarea for entering initials if 'Other' is selected
    initials_textarea = widgets.Textarea(placeholder='Enter your initials here.', description='Add initials:', style={'description_width': 'initial'})
    initials_textarea.layout.visibility = 'hidden'

    def on_initials_change(change):
        if change['new'] == 'Other':
            initials_textarea.layout.visibility = 'visible'
        else:
            initials_textarea.layout.visibility = 'hidden'

    # Register the change event handler
    initials_dropdown.observe(on_initials_change, names='value')
    
    classifications = [('Select', 'Select')] + sorted([(c, c) for c in df_ecg['ElectrocardiogramClassification'].unique()])
    classification_dropdown = widgets.Dropdown(options=classifications, description='Show Users classified as:', style={'description_width': 'initial'})

    review_statuses = [('Select', 'Select')] + sorted([(status, status) for status in df_ecg['ReviewStatus'].unique()])
    review_status_dropdown = widgets.Dropdown(options=review_statuses, description='Review Status:', style={'description_width': 'initial'})

    user_dropdown = widgets.Dropdown(description='Select User ID:', style={'description_width': 'initial'})
    date_dropdown = widgets.Dropdown(description='Select recording date:', style={'description_width': 'initial'})

    diagnosis_dropdown = widgets.Dropdown(options=['Select','Normal', 'Sinus tachycardia', 'SVT', 'EAT', 'AF', 'VT', 'Heart Block','Other'], description='Add diagnosis:', style={'description_width': 'initial'}, layout=Layout(display='none'))
    tracing_quality_dropdown = widgets.Dropdown(options=[('Select', 'Select')] + ['Uninterpretable', 'Poor quality', 'Adequate', 'Good', 'Excellent'], description='Evaluate Tracing Quality:', style={'description_width': 'initial'}, layout=Layout(display='none'))
    notes_textarea = widgets.Textarea(placeholder='Enter your notes here.', description='Add notes:', style={'description_width': 'initial'}, layout=Layout(display='none'))

    plot_output = widgets.Output()

    spacing = '15px'
    for widget in [classification_dropdown, review_status_dropdown, user_dropdown, date_dropdown, diagnosis_dropdown, tracing_quality_dropdown, notes_textarea, initials_dropdown]:
        widget.layout.margin = spacing

    def onClassificationChange(change):
        classification = change['new']
        filtered_data = df_ecg[df_ecg['ElectrocardiogramClassification'] == classification]
        user_ids = sorted(filtered_data['UserId'].unique())
        user_dropdown.options = user_ids if user_ids else ['No users available']
        if user_ids:
            user_dropdown.value = user_ids[0]

    def onReviewChange(change):
        review_statuses = change['new']
        filtered_data = df_ecg[df_ecg['ReviewStatus'] == review_statuses]
        user_ids = sorted(filtered_data['UserId'].unique())
        user_dropdown.options = user_ids if user_ids else ['No users available']
        if user_ids:
            user_dropdown.value = user_ids[0]

    classification_dropdown.observe(onClassificationChange, names='value')
    review_status_dropdown.observe(onReviewChange, names='value')

    def onUserChange(change):
        user_id = change['new']
        classification = classification_dropdown.value
        review_status = review_status_dropdown.value
        if user_id and user_id != 'No users available':
            # Filter dates both by classification and user
            filtered_data = df_ecg[(df_ecg['UserId'] == user_id) & (df_ecg['ElectrocardiogramClassification'] == classification) & (df_ecg['ReviewStatus'] == review_status)]
            dates = sorted(filtered_data['EffectiveDateStart'].unique())
            date_dropdown.options = dates if dates else ['No dates available']
            if dates:
                date_dropdown.value = dates[0]

    user_dropdown.observe(onUserChange, names='value')

    # Define a dictionary to hold the current selection's data
    current_selection = {'user_ecg_data': None}


    get_selections_button = widgets.Button(description='Save', button_style='info', icon='search', layout=Layout(display='none'))
    message_output = widgets.Label() 

    def updatePlot(*args):
        user_id = user_dropdown.value
        date = date_dropdown.value
        if user_id and date and user_id != 'No users available' and date != 'No dates available':
            user_ecg_data = next((d for d in ecg_data if d['UserId'] == user_id and d['EffectiveDateStart'] == date), None)
            # Update the current_selection dictionary with the latest user_ecg_data
            current_selection['user_ecg_data'] = user_ecg_data
            
            if user_ecg_data:
                # Data is available for plotting, show the conditional widgets
                for widget in [diagnosis_dropdown, tracing_quality_dropdown, notes_textarea, get_selections_button]:
                    widget.layout.display = 'flex'  # Make widget visible
                    with plot_output:
                        clear_output(wait=True) 

                        # Check the diagnosis status
                        diagnosis_collection_ref = db.collection('users').document(user_id).collection('Observation').document(user_ecg_data.get('DocumentId')).collection('Diagnosis')
                        diagnosis_docs = list(diagnosis_collection_ref.stream())
                        num_diagnosis_docs = len(diagnosis_docs)

                        diagnosis_status_html = widgets.HTML(value=f"<b style='font-size: larger;'>The number of diagnoses is {num_diagnosis_docs}.</b>")
                        display(diagnosis_status_html)

                        if num_diagnosis_docs != 0:
                            for doc in diagnosis_docs:
                                doc_data = doc.to_dict()
                                physician_initial = doc_data.get('physicianInitials', 'N/A')
                                diagnosis_date = doc_data.get('diagnosisDate', 'N/A')
                                print(f"Physician: {physician_initial}, Diagnosis Date: {diagnosis_date}")
                        
                        heart_rate = int(user_ecg_data.get('HeartRate'))
                        ecg_interpretation = user_ecg_data.get('ElectrocardiogramClassification')

                        heart_rate_html = widgets.HTML(value=f"<b style='font-size: larger;'>Average heart rate: {heart_rate} bpm.</b>")
                        interpretation_html = widgets.HTML(value=f"<b style='font-size: larger;'> Apple Watch interpretation: {ecg_interpretation}.</b>")

                        display(heart_rate_html, interpretation_html)

                        fig, axs = plt.subplots(3, 1, figsize=(15, 6), constrained_layout=True)

                        for i, key in enumerate(['ECGDataRecording1', 'ECGDataRecording2', 'ECGDataRecording3']):
                            ecg = user_ecg_data[key]
                            sample_rate = user_ecg_data.get('SamplingFrequency', 500)  # Default to 500 if not available

                            if ecg:  # Check if there is data for the current key
                                title = f'{key} for UserID {user_id}'
                                plotSingleLeadECG(ecg, sample_rate=sample_rate, title=title, ax=axs[i])
                            else:
                                axs[i].text(0.5, 0.5, 'No data available', horizontalalignment='center', verticalalignment='center', transform=axs[i].transAxes)
                        plt.show()

                else:
                    # No data available for plotting, keep the conditional widgets hidden
                    for widget in [diagnosis_dropdown, tracing_quality_dropdown, notes_textarea, get_selections_button]:
                        widget.layout.display = 'none'
                        
                        with plot_output:
                            clear_output(wait=True)
                            # print("No data for this selection.")
    
    date_dropdown.observe(updatePlot, names='value')


    def getSelections(b):
        user_ecg_data = current_selection['user_ecg_data']
        if user_ecg_data:
                diagnosis_selection = diagnosis_dropdown.value
                tracing_quality_selection = tracing_quality_dropdown.value
                notes_content = notes_textarea.value
                initials_content = initials_dropdown.value

                user_id = user_ecg_data.get('UserId')
                document_id = user_ecg_data.get('DocumentId')
                users_collection_ref = db.collection('users')
                diagnosis_collection_ref = users_collection_ref.document(user_id).collection('Observation').document(document_id).collection('Diagnosis')

                diagnosis_docs = list(diagnosis_collection_ref.stream())
                num_diagnosis_docs = len(diagnosis_docs)

                if num_diagnosis_docs < 3:
                    new_diagnosis_data = {
                        'physicianInitials': initials_content,
                        'physicianDiagnosis': diagnosis_selection,  
                        'tracingQuality': tracing_quality_selection,  
                        'notes': notes_content, 
                        'diagnosisDate': datetime.datetime.now().strftime('%Y-%m-%d_%H:%m')
                        }
                    # Add a new document to the 'Diagnosis' collection
                    new_doc_ref = diagnosis_collection_ref.document()  # This generates a new document ID automatically
                    if initials_content:
                        new_doc_ref.set(new_diagnosis_data)

                        # print('The new diagnosis data have been saved.')
                        message_output.value = 'The new diagnosis data have been saved.'

                        # Update df_ecg - discuss about it
                        df_ecg = read_and_flatten_ecg_data(db)
                        
                    else:
                        print('Your initials are missing. Add them and click SAVE again.')
                elif num_diagnosis_docs >= 3:
                    #  print('The recording has been reviewed. No further diagnosis is required.')
                    message_output.value = 'The recording has already been reviewed. No further diagnosis is required.'

    get_selections_button.on_click(getSelections)

    def clearMessage(*args):
        message_output.value = ''  # Clear the message when new selections are made

    # Bind clearMessage to dropdown changes or other interactions
    classification_dropdown.observe(clearMessage, names='value')
    review_status_dropdown.observe(clearMessage, names='value')
    user_dropdown.observe(clearMessage, names='value')
    date_dropdown.observe(clearMessage, names='value')

    top_layout = widgets.VBox([initials_dropdown, initials_textarea ,classification_dropdown, review_status_dropdown, user_dropdown, date_dropdown])
    bottom_layout = widgets.VBox([plot_output, diagnosis_dropdown, tracing_quality_dropdown, notes_textarea, get_selections_button])
    display(top_layout, bottom_layout, message_output)
