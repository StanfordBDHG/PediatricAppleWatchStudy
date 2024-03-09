#
# This source file is part of the Stanford Spezi open-source project
#
# SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#

import pandas as pd

def convert_string_to_list_of_floats(s: str) -> str:
    if isinstance(s, str):
        return [float(item) for item in s.split()]
    return s 


def save_dataframe_to_csv(df: pd.DataFrame, filename: str):
    df.to_csv(filename, index=False)


def convert_to_snake_case(s: str) -> str:
    return s.lower().replace(" ", "_")
