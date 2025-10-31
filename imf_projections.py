"""
IMF Projections Data Processing - Python Implementation
This script processes IMF World Economic Outlook data with year offset correction
Projections_from_IMF column reads data from the row year - 1 forecast
"""

import pandas as pd
import numpy as np


def process_imf_projections(data):
    """
    Process IMF projections with year - 1 offset

    Args:
        data: DataFrame containing IMF forecast data with columns: year, forecast_year, value

    Returns:
        DataFrame with Projections_from_IMF column showing year - 1 forecast

    Details:
        The Projections_from_IMF column will contain the forecast value from the previous year.
        For example, for year 2024, it will show the forecast that was made in 2023.
    """
    # Validate input
    required_cols = ['year', 'forecast_year', 'value']
    if not all(col in data.columns for col in required_cols):
        raise ValueError(f"Data must contain columns: {required_cols}")

    # Create a copy to avoid modifying original
    result = data.copy()

    # Create lookup for year - 1 forecasts
    # For each year, we want the forecast made in the previous year (forecast_year = year - 1)
    projections_lookup = data[data['year'] == data['forecast_year'] + 1].copy()
    projections_lookup = projections_lookup[['year', 'value']].rename(
        columns={'value': 'Projections_from_IMF'}
    )

    # Merge back to original data
    result = result.merge(projections_lookup, on='year', how='left')

    return result


def create_sample_imf_data():
    """
    Creates sample IMF forecast data and demonstrates the year - 1 offset

    Returns:
        DataFrame with sample IMF forecast data
    """
    # Sample IMF forecast data structure
    # Scenario: Each year, IMF makes forecasts for multiple future years

    imf_data = pd.DataFrame({
        'year': [
            # Forecasts made in 2022 for years 2022-2025
            2022, 2023, 2024, 2025,
            # Forecasts made in 2023 for years 2023-2026
            2023, 2024, 2025, 2026,
            # Forecasts made in 2024 for years 2024-2027
            2024, 2025, 2026, 2027
        ],
        'forecast_year': [
            # Year when forecast was made
            2022, 2022, 2022, 2022,
            2023, 2023, 2023, 2023,
            2024, 2024, 2024, 2024
        ],
        'value': [
            # GDP growth projections (example values)
            3.2, 3.5, 3.8, 4.0,  # 2022 forecasts
            3.1, 3.6, 3.9, 4.1,  # 2023 forecasts
            3.0, 3.4, 3.7, 3.9   # 2024 forecasts
        ],
        'indicator': 'GDP_growth'
    })

    return imf_data


def main():
    """Example demonstration"""
    print("IMF Projections Year Offset Example")
    print("=" * 50)
    print()

    # Create sample data
    sample_data = create_sample_imf_data()

    print("Original IMF Forecast Data:")
    print(sample_data.to_string(index=False))
    print()

    # Process data
    result = process_imf_projections(sample_data)

    print("\nProcessed Data with Projections_from_IMF (year - 1 forecast):")
    print(result.to_string(index=False))
    print()

    print("\nExplanation:")
    print("- For year 2024, Projections_from_IMF shows the forecast made in 2023 (forecast_year = 2023)")
    print("- For year 2023, Projections_from_IMF shows the forecast made in 2022 (forecast_year = 2022)")
    print("- This ensures we're looking at the previous year's projection for each year")
    print()

    # Verification
    print("\nVerification for year 2024:")
    year_2024_data = result[result['year'] == 2024]
    year_2024_prev_forecast = sample_data[
        (sample_data['year'] == 2024) &
        (sample_data['forecast_year'] == 2023)
    ]['value'].iloc[0]

    print(f"Expected (from 2023 forecast): {year_2024_prev_forecast}")
    print(f"Actual (Projections_from_IMF): {year_2024_data['Projections_from_IMF'].iloc[0]}")

    if year_2024_data['Projections_from_IMF'].iloc[0] == year_2024_prev_forecast:
        print("✓ TEST PASSED: Year - 1 offset is working correctly!")
    else:
        print("✗ TEST FAILED: Year - 1 offset not working as expected")


if __name__ == '__main__':
    main()
