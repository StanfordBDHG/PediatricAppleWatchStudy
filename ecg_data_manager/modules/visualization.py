#
# This source file is part of the Stanford Spezi open-source project
#
# SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#

"""
This module provides classes and associated functions for viewing, filtering, and 
analyzing ECG data. The primary class, ECGDataViewer, allows users to interact with 
ECG data through a graphical interface, enabling the review, diagnosis, and visualization 
of ECG recordings. The module also includes functions for plotting single lead ECGs and 
configuring the appearance of the plots.
"""

# Standard library imports
from enum import Enum
from math import ceil
import datetime
from functools import partial

# Related third-party imports
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import ipywidgets as widgets
from ipywidgets import Layout
from IPython.display import display, clear_output
from matplotlib.ticker import AutoMinorLocator
from google.cloud.firestore_v1.client import Client
from google.cloud.exceptions import GoogleCloudError

# Local application/library specific imports
from spezi_data_pipeline.data_flattening.fhir_resources_flattener import ColumnNames

USERS_COLLECTION = "users"
ECG_DATA_SUBCOLLECTION = "HealthKit"
DIAGNOSIS_DATA_SUBCOLLECTION = "Diagnosis"
AGE_GROUP_STRING = "AgeGroup"
SINUS_RHYTHM = "sinusRhythm"


class DiagnosisKeyNames(Enum):
    """
    Enumerates strings related to a diagnosis entry.
    """

    NUMBER_OF_REVIEWERS = "NumberOfReviewers"
    REVIEWERS = "Reviewers"
    REVIEW_STATUS = "ReviewStatus"
    PHYSICIAN_INITIALS = "physicianInitials"
    PHYSICIAN_DIAGNOSIS = "physicianDiagnosis"
    TRACING_QUALITY = "tracingQuality"
    NOTES = "notes"
    DIAGNOSIS_DATE = "diagnosisDate"


class WidgetStrings(Enum):
    """
    Enumerates standardized strings for widgets.
    """

    SELECT = "Select"
    OTHER = "Other"
    COLON_SYMBOL = ":"
    TRACING_QUALITY = "Tracing Quality"
    DIAGNOSIS = "Diagnosis"
    NOTES = "Notes"
    SAVE_DIAGNOSIS = "Save Diagnosis"
    COMPLETE_INITIALS = "Please complete your initials."
    YOUR_INITIALS = "Your Initials:"
    ENTER_INITIALS = "Enter your initials here."
    LOAD_MORE = "LOAD MORE"
    MISSING_INITIALS = (
        "Please select valid initials from the list or enter your initials."
    )
    USER_NOT_FOUND = "User not found"


class TracingQuality(Enum):
    """
    Enumerates standardized options for tracing quality selection.
    """

    UNINTERPRETABLE = "Uninterpretable"
    POOR_QUALITY = "Poor quality"
    ADEQUATE = "Adequate"
    GOOD = "Good"
    EXCELLENT = "Excellent"


class Diagnoses(Enum):
    """
    Enumerates standardized options for diagnosis selection.
    """

    NORMAL_SINUS_RHYTHM = "Normal Sinus Rhythm"
    SINUS_TACHYCARDIA = "Sinus Tachycardia"
    SVT = "SVT"
    EAT = "EAT"
    AF = "AF"
    VT = "VT"
    HEART_BLOCK = "Heart Block"
    OTHER = "Other"


class PlotParams(Enum):
    """
    Enumerates parameters for plotting ECG signals."""

    LWIDTH = 0.5
    AMPLITUTE_ECG = 1.8
    TIME_TICKS = 0.2
    ECG_UNIT = "uV"
    TIME_UNIT = "sec"
    FIG_WIDTH = 15
    FIG_HEIGHT = 2


class ECGDataViewer:  # pylint: disable=too-many-instance-attributes
    """
    A class to view and interact with ECG data.

    Attributes:
        df_ecg (pd.DataFrame): DataFrame containing the ECG data.
        db: Database connection instance.
    """

    def __init__(self, df_ecg: pd.DataFrame, db: Client):
        """
        Initialize the ECGDataViewer with the given ECG DataFrame and database connection.

        Args:
            df_ecg (pd.DataFrame): DataFrame containing the ECG data.
            db: Database connection instance.
        """
        self.db = db
        self.df_ecg = df_ecg
        self.filtered_data = pd.DataFrame()
        self.plot_counter = 0
        self.ecg_output = widgets.Output()
        self.message_output = widgets.Output()
        self.error_output = widgets.Output()
        self.unreviewed_message_widget = widgets.HTML()
        self.setup_widgets()
        self.display_widgets()

    def setup_widgets(self):
        """
        Set up the initial widgets for the viewer.
        """
        unique_initials = (
            pd.Series(self.df_ecg[DiagnosisKeyNames.REVIEWERS.value].explode())
            .dropna()
            .astype(str)
            .unique()
        )
        initials_options = (
            [WidgetStrings.SELECT.value]
            + sorted(unique_initials)
            + [WidgetStrings.OTHER.value]
        )
        self.initials_dropdown = widgets.Dropdown(
            options=initials_options, description=WidgetStrings.YOUR_INITIALS.value
        )
        self.initials_textarea = widgets.Textarea(
            placeholder=WidgetStrings.ENTER_INITIALS.value,
            description=WidgetStrings.YOUR_INITIALS.value,
            layout=Layout(width="300px"),
        )
        self.initials_textarea.layout.visibility = "hidden"
        self.initials_dropdown.observe(self.on_initials_change, names="value")

        self.load_more_button = widgets.Button(
            description=WidgetStrings.LOAD_MORE.value,
            button_style="info",
            icon="plus",
            layout=Layout(width="200px", height="50px"),
        )
        self.load_more_button.on_click(self.load_more_ecg)

    def on_initials_change(self, change):
        """
        Handle changes in the initials dropdown widget.

        Args:
            change: The change event from the dropdown widget.
        """
        self.clear_outputs()  # Clear outputs on any change in dropdown
        self.plot_counter = 0

        if change["new"] == WidgetStrings.OTHER.value:
            self.initials_textarea.layout.visibility = "visible"
            self.error_output.clear_output()
        elif change["new"] == WidgetStrings.SELECT.value:
            with self.error_output:
                clear_output()
                print(WidgetStrings.COMPLETE_INITIALS.value)
        else:
            self.initials_textarea.layout.visibility = "hidden"
            self.update_unreviewed_message()

    def display_widgets(self):
        """
        Display the initial widgets.
        """
        display(
            self.initials_dropdown,
            self.initials_textarea,
            self.unreviewed_message_widget,
            self.ecg_output,
            self.message_output,
            self.error_output,
            self.load_more_button,
        )

    def clear_outputs(self):
        """
        Clear the output widgets.
        """
        self.ecg_output.clear_output()
        self.message_output.clear_output()
        self.error_output.clear_output()
        self.unreviewed_message_widget.value = ""

    def update_unreviewed_message(self):
        """
        Update the message widget with the number of unreviewed ECGs.
        """
        initials = (
            self.initials_textarea.value.strip()
            if self.initials_dropdown.value == WidgetStrings.OTHER.value
            else self.initials_dropdown.value
        )
        self.apply_filters(
            initials
        )  # Apply filters to determine the number of unreviewed ECGs
        total_unreviewed = len(self.filtered_data)
        message = (
            f"<b style='font-size: large;'>Total unreviewed recordings for "
            f"{initials}: {total_unreviewed}</b>"
        )
        self.unreviewed_message_widget.value = message

    def load_more_ecg(self, b=None):  # pylint: disable=unused-argument
        """
        Load more ECG data for review.

        Args:
            b: Button click event (default is None).
        """
        initials = (
            self.initials_textarea.value.strip()
            if self.initials_dropdown.value == WidgetStrings.OTHER.value
            else self.initials_dropdown.value
        )
        if initials == WidgetStrings.SELECT.value:
            with self.error_output:
                clear_output()
                print(WidgetStrings.MISSING_INITIALS.value)
            return

        self.update_unreviewed_message()
        if self.plot_counter < len(self.filtered_data):
            self.plot_ecg_data()
        else:
            with self.message_output:
                clear_output()
                display(
                    widgets.HTML(
                        value="<b style='color: green; font-size: 22px;'>No more ECG data "
                        "to review.✓</b>"
                    )
                )

    def apply_filters(self, initials):
        """
        Apply filters to the ECG data based on the review status and initials.

        Args:
            initials (str): The initials to filter by.
        """
        if self.initials_dropdown.value == WidgetStrings.OTHER.value:
            self.filtered_data = self.df_ecg[
                self.df_ecg[DiagnosisKeyNames.REVIEW_STATUS.value]
                == "Incomplete review"
            ]
        else:
            self.filtered_data = self.df_ecg[
                (
                    self.df_ecg[DiagnosisKeyNames.REVIEW_STATUS.value]
                    == "Incomplete review"
                )
                & (
                    self.df_ecg[DiagnosisKeyNames.REVIEWERS.value].apply(
                        lambda x: initials not in x
                    )
                )
            ]

    def plot_ecg_data(self):
        """
        Plot the ECG data.
        """
        with self.ecg_output:
            clear_output(wait=True)
            onscreen_plots = 1
            for _, row in self.filtered_data.iloc[
                self.plot_counter : self.plot_counter + onscreen_plots
            ].iterrows():
                self.plot_single_ecg(row)
                self.create_diagnosis_widgets(
                    row[ColumnNames.USER_ID.value], row[ColumnNames.RESOURCE_ID.value]
                )
            self.plot_counter += onscreen_plots

    def plot_single_ecg(self, row):  # pylint: disable=too-many-locals
        """
        Plot a single ECG recording.

        Args:
            row (pd.Series): The row of the DataFrame containing the ECG data.
        """
        _, axs = plt.subplots(3, 1, figsize=(14, 5), constrained_layout=True)

        for i, key in enumerate(
            ["ECGDataRecording1", "ECGDataRecording2", "ECGDataRecording3"]
        ):
            title = f"ECG part {i+1} recorded on {row['EffectiveDateTimeHHMM']}"
            plot_single_lead_ecg(
                row[key],
                sample_rate=row[ColumnNames.SAMPLING_FREQUENCY.value],
                title=title,
                ax=axs[i],
            )

        user_id = (
            row[ColumnNames.USER_ID.value]
            if row[ColumnNames.USER_ID.value] is not None
            else "Unknown"
        )
        heart_rate = (
            int(row[ColumnNames.HEART_RATE.value])
            if row[ColumnNames.HEART_RATE.value] is not None
            else "Unknown"
        )
        ecg_interpretation = (
            row[ColumnNames.APPLE_ELECTROCARDIOGRAM_CLASSIFICATION.value]
            if row[ColumnNames.APPLE_ELECTROCARDIOGRAM_CLASSIFICATION.value] is not None
            else "Unknown"
        )

        symptoms = row.get("Symptoms", "No symptoms reported.")

        group_class = row[AGE_GROUP_STRING]
        user_id_html = widgets.HTML(
            value=f"<b style='font-size: larger;'><span style='color: blue;'>{group_class}</span> "
            f"User ID {user_id}</b>"
        )

        heart_rate_html = widgets.HTML(
            value=f"<b style='font-size: larger;'>Average HR: {heart_rate} bpm</b>"
        )

        symptoms_html = widgets.HTML(value=f"<b style='font-size: larger;'>Symptoms: {symptoms}</b>")

        interpretation_html = widgets.HTML(
            value="<b style='font-size: larger;'>Classification: "
        )

        # Conditional color for non-sinusRhythm classifications
        if ecg_interpretation != SINUS_RHYTHM:
            interpretation_html.value += (
                f"<span style='color: red;'>{ecg_interpretation}</span>"
            )
        else:
            interpretation_html.value += f"{ecg_interpretation}"

        interpretation_html.value += "</b>"

        display(user_id_html, heart_rate_html, symptoms_html, interpretation_html)

        # Add review status
        diagnosis_collection_ref = (
            self.db.collection(USERS_COLLECTION)
            .document(user_id)
            .collection(ECG_DATA_SUBCOLLECTION)
            .document(row[ColumnNames.RESOURCE_ID.value])
            .collection(DIAGNOSIS_DATA_SUBCOLLECTION)
        )
        diagnosis_docs = list(diagnosis_collection_ref.stream())
        num_diagnosis_docs = len(diagnosis_docs)

        diagnosis_status_html = widgets.HTML(
            value="<b style='font-size: larger;'>This recording has been reviewed "
            f"{num_diagnosis_docs} times:</b>"
        )
        display(diagnosis_status_html)

        if num_diagnosis_docs != 0:
            for doc in diagnosis_docs:
                doc_data = doc.to_dict()
                physician_initial = doc_data.get(
                    DiagnosisKeyNames.PHYSICIAN_INITIALS.value, "N/A"
                )
                diagnosis_date = doc_data.get(
                    DiagnosisKeyNames.DIAGNOSIS_DATE.value, "N/A"
                )
                reviewers_html = widgets.HTML(
                    value=f"<span style='font-size: larger;'>Physician: "
                    f"{physician_initial}, Date: {diagnosis_date}</span>"
                )
                display(reviewers_html)

        plt.show()

    def create_diagnosis_widgets(self, user_id, document_id):
        """
        Create and display widgets for diagnosing an ECG recording.

        Args:
            user_id (str): The user ID associated with the ECG recording.
            document_id (str): The document ID of the ECG recording.
        """
        message_output_specific = widgets.Output()

        diagnosis_dropdown = widgets.Dropdown(
            options=[
                WidgetStrings.SELECT.value,
                Diagnoses.NORMAL_SINUS_RHYTHM.value,
                Diagnoses.SINUS_TACHYCARDIA.value,
                Diagnoses.SVT.value,
                Diagnoses.EAT.value,
                Diagnoses.AF.value,
                Diagnoses.VT.value,
                Diagnoses.HEART_BLOCK.value,
                Diagnoses.OTHER.value,
            ],
            description=WidgetStrings.DIAGNOSIS.value
            + WidgetStrings.COLON_SYMBOL.value,
        )
        diagnosis_dropdown.style.description_width = "120px"

        tracing_quality_dropdown = widgets.Dropdown(
            options=[
                WidgetStrings.SELECT.value,
                TracingQuality.UNINTERPRETABLE.value,
                TracingQuality.POOR_QUALITY.value,
                TracingQuality.ADEQUATE.value,
                TracingQuality.GOOD.value,
                TracingQuality.EXCELLENT.value,
            ],
            description=WidgetStrings.TRACING_QUALITY.value
            + WidgetStrings.COLON_SYMBOL.value,
        )
        tracing_quality_dropdown.style.description_width = "140px"

        notes_textarea = widgets.Textarea(
            description=WidgetStrings.NOTES.value + WidgetStrings.COLON_SYMBOL.value
        )
        save_button = widgets.Button(
            description=WidgetStrings.SAVE_DIAGNOSIS.value,
            button_style="success",
            icon="save",
            layout=Layout(width="250px", height="50px"),
        )

        def hide_widgets(b):  # pylint: disable=unused-argument
            save_button.on_click(
                partial(
                    self.save_diagnosis,
                    user_id,
                    document_id,
                    diagnosis_dropdown,
                    tracing_quality_dropdown,
                    notes_textarea,
                    message_output_specific,
                )
            )

            # Hide the widgets if not all selections have been made
            initials = (
                self.initials_dropdown.value
                if self.initials_dropdown.value != WidgetStrings.OTHER.value
                else self.initials_textarea.value.strip()
            )
            if WidgetStrings.SELECT.value in (
                diagnosis_dropdown.value,
                tracing_quality_dropdown.value,
                initials,
            ):
                diagnosis_dropdown.layout.visibility = "hidden"
                tracing_quality_dropdown.layout.visibility = "hidden"
                notes_textarea.layout.visibility = "hidden"

        # Attach the hide_widgets function to the button's on_click event
        save_button.on_click(hide_widgets)

        # Display the widgets
        widgets_box = widgets.VBox(
            [
                diagnosis_dropdown,
                tracing_quality_dropdown,
                notes_textarea,
                save_button,
                message_output_specific,
            ]
        )
        display(widgets_box)

        return widgets_box

    def save_diagnosis(  # pylint: disable=too-many-locals, too-many-arguments
        self,
        user_id,
        document_id,
        diagnosis_dropdown,
        tracing_quality_dropdown,
        notes_textarea,
        message_output_specific,
        b=None,  # pylint: disable=unused-argument
    ):
        """
        Save the diagnosis for an ECG recording.

        Args:
            user_id (str): The user ID associated with the ECG recording.
            document_id (str): The document ID of the ECG recording.
            diagnosis_dropdown (widgets.Dropdown): The dropdown widget for diagnosis.
            tracing_quality_dropdown (widgets.Dropdown): The dropdown widget for tracing quality.
            notes_textarea (widgets.Textarea): The textarea widget for notes.
            message_output_specific (widgets.Output): The output widget for messages.
            b: Button click event (default is None).
        """
        with message_output_specific:
            clear_output(wait=True)
            diagnosis = diagnosis_dropdown.value
            tracing_quality = tracing_quality_dropdown.value
            notes = notes_textarea.value
            initials = (
                self.initials_dropdown.value
                if self.initials_dropdown.value != WidgetStrings.OTHER.value
                else self.initials_textarea.value.strip()
            )

            if WidgetStrings.SELECT.value in (diagnosis, tracing_quality, initials):
                missing_fields_html = widgets.HTML(
                    value="<span style='color: red; font-size: 20px;'>Complete "
                    "all fields before saving.</span>"
                )
                display(missing_fields_html)

                return

            user_ref = self.db.collection(USERS_COLLECTION).document(user_id)
            recording_ref = user_ref.collection(ECG_DATA_SUBCOLLECTION).document(
                document_id
            )
            diagnosis_ref = recording_ref.collection(DIAGNOSIS_DATA_SUBCOLLECTION)
            num_diagnosis_docs = len(list(diagnosis_ref.stream()))

            new_diagnosis_data = {
                DiagnosisKeyNames.PHYSICIAN_INITIALS.value: initials,
                DiagnosisKeyNames.PHYSICIAN_DIAGNOSIS.value: diagnosis,
                DiagnosisKeyNames.TRACING_QUALITY.value: tracing_quality,
                DiagnosisKeyNames.NOTES.value: notes,
                DiagnosisKeyNames.DIAGNOSIS_DATE.value: datetime.datetime.now().strftime(
                    "%Y-%m-%d %H:%M"
                ),
            }

            try:  # pylint: disable=too-many-nested-blocks
                if num_diagnosis_docs < 3:
                    diagnosis_doc_ref = diagnosis_ref.document()
                    diagnosis_doc_ref.set(new_diagnosis_data)

                    # Update the ecg_df using the document_id as index
                    index = self.df_ecg.index[
                        self.df_ecg[ColumnNames.RESOURCE_ID.value] == document_id
                    ].tolist()
                    if index:
                        for idx in index:
                            if idx in self.df_ecg.index:
                                self.df_ecg.at[
                                    idx, DiagnosisKeyNames.NUMBER_OF_REVIEWERS.value
                                ] += 1
                                if isinstance(
                                    self.df_ecg.at[
                                        idx, DiagnosisKeyNames.REVIEWERS.value
                                    ],
                                    list,
                                ):
                                    self.df_ecg.at[
                                        idx, DiagnosisKeyNames.REVIEWERS.value
                                    ].append(initials)
                                    self.df_ecg.at[
                                        idx, DiagnosisKeyNames.REVIEW_STATUS.value
                                    ] = (
                                        "Incomplete review"
                                        if self.df_ecg.at[
                                            idx,
                                            DiagnosisKeyNames.NUMBER_OF_REVIEWERS.value,
                                        ]
                                        < 3
                                        else "Complete review"
                                    )

                    data_saved_html = widgets.HTML(
                        value="<span style='color: green; font-size: 20px;'>Diagnosis "
                        "saved successfully.✓</span>"
                    )
                    display(data_saved_html)
                else:
                    print(
                        "ECG has already been reviewed. No further review is required."
                    )

            except GoogleCloudError as gce:
                error_html = widgets.HTML(
                    value="<span style='color: red; font-size: 20px;'>Error saving "
                    f"diagnosis: {gce}</span>"
                )
                display(error_html)
            except KeyError as ke:
                error_html = widgets.HTML(
                    value=f"<span style='color: red; font-size: 20px;'>Key error: {ke}</span>"
                )
                display(error_html)
            except TypeError as te:
                error_html = widgets.HTML(
                    value=f"<span style='color: red; font-size: 20px;'>Type error: {te}</span>"
                )
                display(error_html)


def _ax_plot(ax, x, y, secs):
    """
    Plot the ECG data on the given axis.

    Args:
        ax (plt.Axes): The axis to plot on.
        x (np.ndarray): The x values of the plot.
        y (np.ndarray): The y values of the plot.
        secs (float): The duration of the ECG recording in seconds.
    """
    ax.set_xticks(
        np.arange(
            0,
            secs + PlotParams.TIME_TICKS.value,
            PlotParams.TIME_TICKS.value,
        )
    )
    ax.set_yticks(
        np.arange(
            -ceil(PlotParams.AMPLITUTE_ECG.value),
            ceil(PlotParams.AMPLITUTE_ECG.value),
            1.0,
        )
    )

    ax.minorticks_on()
    ax.xaxis.set_minor_locator(AutoMinorLocator(5))
    ax.set_ylim(-PlotParams.AMPLITUTE_ECG.value, PlotParams.AMPLITUTE_ECG.value)
    ax.set_xlim(0, secs)

    ax.grid(which="major", linestyle="-", linewidth="0.5", color="red")
    ax.grid(which="minor", linestyle="-", linewidth="0.5", color=(1, 0.7, 0.7))

    ax.plot(x, y, linewidth=PlotParams.LWIDTH.value)


def plot_single_lead_ecg(
    ecg: list | np.ndarray,
    sample_rate: int = 500,
    title: str = "ECG",
    ax: plt.Axes | None = None,
) -> None:
    """
    Plot a single lead ECG chart.

    Args:
        ecg (list | np.ndarray): ECG signal data.
        sample_rate (int): Sample rate of the signal.
        title (str): Title to be shown on the chart.
        ax (plt.Axes | None): The axis to plot on (default is None).
    """
    if ax is None:
        plt.figure(figsize=(PlotParams.FIG_WIDTH.value, PlotParams.FIG_HEIGHT.value))
        ax = plt.gca()

    ax.set_title(title)
    ax.set_ylabel(PlotParams.ECG_UNIT.value)
    ax.set_xlabel(PlotParams.TIME_UNIT.value)
    seconds = len(ecg) / sample_rate

    step = 1.0 / sample_rate
    _ax_plot(ax, np.arange(0, len(ecg) * step, step), ecg, seconds)


class ECGDataExplorer:  # pylint: disable=too-many-instance-attributes
    """
    A class used to explore and visualize ECG data interactively.

    Attributes:
        data (pd.DataFrame): The original ECG data.
        filtered_data (pd.DataFrame): The filtered ECG data.
        age_group_dropdown (widgets.Dropdown): Dropdown widget for selecting the age group.
        ecg_class_dropdown (widgets.Dropdown): Dropdown widget for selecting the ECG classification.
        user_id_dropdown (widgets.Dropdown): Dropdown widget for selecting the user ID.
        date_time_dropdown (widgets.Dropdown): Dropdown widget for selecting the date and time.
        load_data_button (widgets.Button): Button widget for loading and plotting the data.
        output (widgets.Output): Output widget for displaying the plots and information.
    """

    def __init__(self, data):
        """
        Initializes the ECGDataExplorer with the given data and sets up the interactive widgets.

        Args:
            data (pd.DataFrame): The ECG data to be explored.
        """
        self.data = data
        self.filtered_data = data.copy()

        self.age_group_dropdown = widgets.Dropdown(
            options=self.get_unique_values_with_all(AGE_GROUP_STRING),
            description="Age Group",
            value="All",
            layout=widgets.Layout(padding="10px 0px 30px 40px"),
        )

        self.ecg_class_dropdown = widgets.Dropdown(
            options=self.get_unique_values_with_all(
                ColumnNames.APPLE_ELECTROCARDIOGRAM_CLASSIFICATION.value
            ),
            description="ECG Class",
            value="All",
            layout=widgets.Layout(padding="10px 0px 30px 40px"),
        )

        self.user_id_dropdown = widgets.Dropdown(
            options=self.get_unique_values_with_all(ColumnNames.USER_ID.value),
            description="User ID",
            value="All",
            layout=widgets.Layout(padding="10px 0px 30px 40px"),
        )

        self.date_time_dropdown = widgets.Dropdown(
            options=self.get_unique_values_with_all("EffectiveDateTimeHHMM"),
            description="Date",
            value="All",
            layout=widgets.Layout(padding="10px 0px 40px 40px"),
        )

        self.load_data_button = widgets.Button(
            description="LOAD DATA+",
            button_style="success",
            layout=widgets.Layout(
                width="200px", height="50px", padding="10px 40px 10px 40px"
            ),
        )

        self.age_group_dropdown.observe(self.filter_data, names="value")
        self.ecg_class_dropdown.observe(self.filter_data, names="value")
        self.user_id_dropdown.observe(self.filter_data, names="value")
        self.date_time_dropdown.observe(self.filter_data, names="value")
        self.load_data_button.on_click(self.plot_ecg_recording)

        display(
            self.age_group_dropdown,
            self.ecg_class_dropdown,
            self.user_id_dropdown,
            self.date_time_dropdown,
            self.load_data_button,
        )

        self.output = widgets.Output()
        display(self.output)

    def get_unique_values_with_all(self, column):
        """
        Get unique values from a column including an "All" option.

        Args:
            column (str): The name of the column from which to get unique values.

        Returns:
            list: A list of unique values with "All" as the first option.
        """
        unique_values = self.data[column].astype(str).unique().tolist()
        unique_values.insert(0, "All")
        return unique_values

    def filter_data(self, change=None):  # pylint: disable=unused-argument
        """
        Filters the data based on the selected dropdown values and updates the dropdown options.

        Args:
            change (dict, optional): The change event from the dropdown widgets. Defaults to None.
        """
        self.filtered_data = self.data.copy()

        if self.age_group_dropdown.value != "All":
            self.filtered_data = self.filtered_data[
                self.filtered_data[AGE_GROUP_STRING] == self.age_group_dropdown.value
            ]

        if self.ecg_class_dropdown.value != "All":
            self.filtered_data = self.filtered_data[
                self.filtered_data[
                    ColumnNames.APPLE_ELECTROCARDIOGRAM_CLASSIFICATION.value
                ]
                == self.ecg_class_dropdown.value
            ]

        self.update_user_id_dropdown_options()

        if self.user_id_dropdown.value != "All":
            self.filtered_data = self.filtered_data[
                self.filtered_data[ColumnNames.USER_ID.value]
                == self.user_id_dropdown.value
            ]

        self.update_date_time_dropdown_options()

        if self.date_time_dropdown.value != "All":
            self.filtered_data = self.filtered_data[
                self.filtered_data["EffectiveDateTimeHHMM"]
                == self.date_time_dropdown.value
            ]

        self.update_dropdown_options()

    def update_dropdown_options(self):
        """
        Updates the options for the age group and ECG class dropdowns based on the current data.
        """
        self.age_group_dropdown.options = self.get_unique_values_with_all_column(
            self.data, AGE_GROUP_STRING
        )
        self.ecg_class_dropdown.options = self.get_unique_values_with_all_column(
            self.data, ColumnNames.APPLE_ELECTROCARDIOGRAM_CLASSIFICATION.value
        )

    def update_user_id_dropdown_options(self):
        """
        Updates the options for the user ID dropdown based on the filtered data.
        """
        filtered_for_user_ids = self.data.copy()

        if self.age_group_dropdown.value != "All":
            filtered_for_user_ids = filtered_for_user_ids[
                filtered_for_user_ids[AGE_GROUP_STRING] == self.age_group_dropdown.value
            ]

        if self.ecg_class_dropdown.value != "All":
            filtered_for_user_ids = filtered_for_user_ids[
                filtered_for_user_ids[
                    ColumnNames.APPLE_ELECTROCARDIOGRAM_CLASSIFICATION.value
                ]
                == self.ecg_class_dropdown.value
            ]

        self.user_id_dropdown.options = self.get_unique_values_with_all_column(
            filtered_for_user_ids, ColumnNames.USER_ID.value
        )

    def update_date_time_dropdown_options(self):
        """
        Updates the options for the date and time dropdown based on the filtered data.
        """
        filtered_for_dates = self.data.copy()

        if self.age_group_dropdown.value != "All":
            filtered_for_dates = filtered_for_dates[
                filtered_for_dates[AGE_GROUP_STRING] == self.age_group_dropdown.value
            ]

        if self.ecg_class_dropdown.value != "All":
            filtered_for_dates = filtered_for_dates[
                filtered_for_dates[
                    ColumnNames.APPLE_ELECTROCARDIOGRAM_CLASSIFICATION.value
                ]
                == self.ecg_class_dropdown.value
            ]

        if self.user_id_dropdown.value != "All":
            filtered_for_dates = filtered_for_dates[
                filtered_for_dates[ColumnNames.USER_ID.value]
                == self.user_id_dropdown.value
            ]

        self.date_time_dropdown.options = self.get_unique_values_with_all_column(
            filtered_for_dates, "EffectiveDateTimeHHMM"
        )

    def get_unique_values_with_all_column(self, data, column):
        """
        Get unique values from a specific column including an "All" option.

        Args:
            data (pd.DataFrame): The data from which to get unique values.
            column (str): The name of the column from which to get unique values.

        Returns:
            list: A list of unique values with "All" as the first option.
        """
        unique_values = data[column].astype(str).unique().tolist()
        unique_values.insert(0, "All")
        return unique_values

    def plot_ecg_recording(self, change=None):  # pylint: disable=unused-argument
        """
        Plots the filtered ECG recordings.

        Args:
            change (dict, optional): The change event from the load data button. Defaults to None.
        """
        with self.output:
            clear_output(wait=True)
            if not self.filtered_data.empty:
                for _, row in self.filtered_data.iterrows():
                    self.plot_single_ecg(row)

    def plot_single_ecg(self, row):  # pylint: disable=too-many-locals
        """
        Plot a single ECG recording.

        Args:
            row (pd.Series): The row of the DataFrame containing the ECG data.
        """
        _, axs = plt.subplots(3, 1, figsize=(14, 5), constrained_layout=True)

        for i, key in enumerate(
            ["ECGDataRecording1", "ECGDataRecording2", "ECGDataRecording3"]
        ):
            title = f"ECG part {i+1} recorded on {row[ColumnNames.EFFECTIVE_DATE_TIME.value]}"
            plot_single_lead_ecg(
                row[key],
                sample_rate=row[ColumnNames.SAMPLING_FREQUENCY.value],
                title=title,
                ax=axs[i],
            )

        user_id = (
            row[ColumnNames.USER_ID.value]
            if row[ColumnNames.USER_ID.value] is not None
            else "Unknown"
        )
        heart_rate = (
            int(row[ColumnNames.HEART_RATE.value])
            if row[ColumnNames.HEART_RATE.value] is not None
            else "Unknown"
        )
        ecg_interpretation = (
            row[ColumnNames.APPLE_ELECTROCARDIOGRAM_CLASSIFICATION.value]
            if row[ColumnNames.APPLE_ELECTROCARDIOGRAM_CLASSIFICATION.value] is not None
            else "Unknown"
        )

        group_class = row[AGE_GROUP_STRING]
        user_id_html = widgets.HTML(
            value=f"<b style='font-size: larger;'><span style='color: blue;'>{group_class}</span> "
            f"User ID {user_id}</b>"
        )

        heart_rate_html = widgets.HTML(
            value=f"<b style='font-size: larger;'>Average HR: {heart_rate} bpm</b>"
        )
        interpretation_html = widgets.HTML(
            value="<b style='font-size: larger;'>Classification: "
        )

        if ecg_interpretation != SINUS_RHYTHM:
            interpretation_html.value += (
                f"<span style='color: red;'>{ecg_interpretation}</span>"
            )
        else:
            interpretation_html.value += f"{ecg_interpretation}"

        interpretation_html.value += "</b>"

        display(user_id_html, heart_rate_html, interpretation_html)

        diagnosis_status_html = widgets.HTML(
            value=f"<b style='font-size: larger;'>This recording has been reviewed "
            f"{row.get('NumberOfReviewers')} times:</b>"
        )
        display(diagnosis_status_html)

        if row.get(DiagnosisKeyNames.NUMBER_OF_REVIEWERS.value) != 0:
            for index, _ in enumerate(row.get(DiagnosisKeyNames.REVIEWERS.value, [])):
                reviewers_initials = row.get(
                    f"Diagnosis{index+1}_physicianInitials", ""
                )
                diagnosis_date = row.get(f"Diagnosis{index+1}_diagnosisDate", "")
                reviewers_html = widgets.HTML(
                    value=f"<span style='font-size: larger;'><b>Physician: {reviewers_initials}, "
                    f"Date: {diagnosis_date}</b></span>"
                )
                display(reviewers_html)

        plt.show()
