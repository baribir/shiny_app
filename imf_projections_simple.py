"""
IMF Projections Data Processing - Simple Python Implementation (No Dependencies)
This script processes IMF World Economic Outlook data with year offset correction
Projections_from_IMF column reads data from the row year - 1 forecast
"""


def process_imf_projections(data):
    """
    Process IMF projections with year - 1 offset

    Args:
        data: List of dictionaries with keys: year, forecast_year, value

    Returns:
        List of dictionaries with added Projections_from_IMF field

    Details:
        The Projections_from_IMF column will contain the forecast value from the previous year.
        For example, for year 2024, it will show the forecast that was made in 2023.
    """
    # Create a lookup dictionary: year -> value from (year-1) forecast
    projections_lookup = {}

    for row in data:
        year = row['year']
        forecast_year = row['forecast_year']
        value = row['value']

        # If this forecast was made in year-1, store it for lookup
        if forecast_year == year - 1:
            projections_lookup[year] = value

    # Add Projections_from_IMF to each row
    result = []
    for row in data:
        new_row = row.copy()
        year = row['year']
        # Get the projection from year - 1 forecast
        new_row['Projections_from_IMF'] = projections_lookup.get(year, None)
        result.append(new_row)

    return result


def create_sample_imf_data():
    """
    Creates sample IMF forecast data

    Returns:
        List of dictionaries with sample IMF forecast data
    """
    imf_data = [
        # Forecasts made in 2022 for years 2022-2025
        {'year': 2022, 'forecast_year': 2022, 'value': 3.2, 'indicator': 'GDP_growth'},
        {'year': 2023, 'forecast_year': 2022, 'value': 3.5, 'indicator': 'GDP_growth'},
        {'year': 2024, 'forecast_year': 2022, 'value': 3.8, 'indicator': 'GDP_growth'},
        {'year': 2025, 'forecast_year': 2022, 'value': 4.0, 'indicator': 'GDP_growth'},

        # Forecasts made in 2023 for years 2023-2026
        {'year': 2023, 'forecast_year': 2023, 'value': 3.1, 'indicator': 'GDP_growth'},
        {'year': 2024, 'forecast_year': 2023, 'value': 3.6, 'indicator': 'GDP_growth'},
        {'year': 2025, 'forecast_year': 2023, 'value': 3.9, 'indicator': 'GDP_growth'},
        {'year': 2026, 'forecast_year': 2023, 'value': 4.1, 'indicator': 'GDP_growth'},

        # Forecasts made in 2024 for years 2024-2027
        {'year': 2024, 'forecast_year': 2024, 'value': 3.0, 'indicator': 'GDP_growth'},
        {'year': 2025, 'forecast_year': 2024, 'value': 3.4, 'indicator': 'GDP_growth'},
        {'year': 2026, 'forecast_year': 2024, 'value': 3.7, 'indicator': 'GDP_growth'},
        {'year': 2027, 'forecast_year': 2024, 'value': 3.9, 'indicator': 'GDP_growth'},
    ]

    return imf_data


def print_table(data, title=""):
    """Pretty print data as a table"""
    if title:
        print(title)
        print("=" * 80)

    if not data:
        print("No data")
        return

    # Get all keys
    keys = list(data[0].keys())

    # Print header
    header = " | ".join(f"{key:20}" for key in keys)
    print(header)
    print("-" * len(header))

    # Print rows
    for row in data:
        values = " | ".join(f"{str(row.get(key, '')):20}" for key in keys)
        print(values)

    print()


def main():
    """Example demonstration"""
    print("\nIMF Projections Year Offset Example")
    print("=" * 80)
    print()

    # Create sample data
    sample_data = create_sample_imf_data()

    print_table(sample_data, "Original IMF Forecast Data:")

    # Process data
    result = process_imf_projections(sample_data)

    print_table(result, "Processed Data with Projections_from_IMF (year - 1 forecast):")

    print("\nExplanation:")
    print("-" * 80)
    print("• For year 2024, Projections_from_IMF shows the forecast made in 2023")
    print("  (where forecast_year = 2023)")
    print()
    print("• For year 2023, Projections_from_IMF shows the forecast made in 2022")
    print("  (where forecast_year = 2022)")
    print()
    print("• This ensures we're looking at the PREVIOUS YEAR'S projection for each year")
    print("=" * 80)
    print()

    # Verification
    print("Verification for year 2024:")
    print("-" * 80)

    year_2024_data = [row for row in result if row['year'] == 2024]

    # Find the expected value (2023 forecast for 2024)
    expected = next(
        (row['value'] for row in sample_data
         if row['year'] == 2024 and row['forecast_year'] == 2023),
        None
    )

    print(f"Expected (from 2023 forecast for year 2024): {expected}")

    if year_2024_data:
        actual = year_2024_data[0]['Projections_from_IMF']
        print(f"Actual (Projections_from_IMF):             {actual}")
        print()

        if actual == expected:
            print("✓ TEST PASSED: Year - 1 offset is working correctly!")
        else:
            print("✗ TEST FAILED: Year - 1 offset not working as expected")
    else:
        print("No data found for year 2024")

    print()

    # Additional examples
    print("\nDetailed Examples:")
    print("-" * 80)

    for year in [2023, 2024, 2025]:
        year_data = [row for row in result if row['year'] == year and row['forecast_year'] == year]
        if year_data:
            row = year_data[0]
            print(f"Year {year}:")
            print(f"  Current forecast (made in {year}): {row['value']}")
            print(f"  Previous year projection:           {row['Projections_from_IMF']}")
            print()


if __name__ == '__main__':
    main()
