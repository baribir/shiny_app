# IMF Projections Year Offset Fix

## Overview

This implementation fixes the `Projections_from_IMF` column to correctly read data from the **year - 1 forecast**.

## Problem Statement

When working with IMF World Economic Outlook data, we need to compare current forecasts with previous years' projections. The `Projections_from_IMF` column should show what was forecasted for each year in the **previous year's** forecast.

### Example

For **year 2024**:
- Current forecast (made in 2024): 3.0
- **Projections_from_IMF**: 3.6 ← This is the forecast made in **2023** for year 2024

## Implementation

### Files Created

1. **`imf_projections.R`** - R implementation with dplyr
2. **`imf_projections.py`** - Python implementation with pandas
3. **`imf_projections_simple.py`** - Python implementation without dependencies (standalone)
4. **`test_imf_projections.R`** - R test suite

### Key Logic

The core logic is:

```
For each row with year = Y:
  Projections_from_IMF = forecast value where (year = Y AND forecast_year = Y - 1)
```

### Data Structure

Input data should have these columns:
- `year`: The year being forecasted
- `forecast_year`: The year when the forecast was made
- `value`: The forecasted value
- `indicator`: Type of indicator (e.g., GDP_growth, inflation)

### Example Data Flow

```
Input:
| year | forecast_year | value | indicator  |
|------|---------------|-------|------------|
| 2023 | 2022          | 3.5   | GDP_growth |
| 2024 | 2023          | 3.6   | GDP_growth |
| 2024 | 2024          | 3.0   | GDP_growth |

Output:
| year | forecast_year | value | indicator  | Projections_from_IMF |
|------|---------------|-------|------------|----------------------|
| 2023 | 2022          | 3.5   | GDP_growth | 3.5                  |
| 2024 | 2023          | 3.6   | GDP_growth | 3.6                  |
| 2024 | 2024          | 3.0   | GDP_growth | 3.6                  |
```

Notice how:
- Year 2024 (forecast made in 2024) has `Projections_from_IMF = 3.6`
- This 3.6 comes from the row where `year = 2024` and `forecast_year = 2023`
- This represents what was projected **last year** (2023) for year 2024

## Usage

### Python (Simple Version - No Dependencies)

```python
from imf_projections_simple import process_imf_projections

# Your IMF data
data = [
    {'year': 2024, 'forecast_year': 2023, 'value': 3.6, 'indicator': 'GDP'},
    {'year': 2024, 'forecast_year': 2024, 'value': 3.0, 'indicator': 'GDP'},
]

# Process with year - 1 offset
result = process_imf_projections(data)

# result will have Projections_from_IMF column added
```

### R Version

```r
source("imf_projections.R")

# Your IMF data
data <- data.frame(
  year = c(2024, 2024),
  forecast_year = c(2023, 2024),
  value = c(3.6, 3.0),
  indicator = c("GDP", "GDP")
)

# Process with year - 1 offset
result <- process_imf_projections_efficient(data)
```

## Testing

Run the simple Python test (no dependencies required):

```bash
python3 imf_projections_simple.py
```

Expected output:
```
✓ TEST PASSED: Year - 1 offset is working correctly!
```

## Integration with Existing Code

To integrate this into a Shiny app:

1. **In `server.R`**, source the script:
   ```r
   source("imf_projections.R")
   ```

2. **Process your IMF data**:
   ```r
   # Load your IMF data
   imf_data <- read.csv("your_imf_data.csv")

   # Apply the year - 1 offset
   imf_data_processed <- process_imf_projections_efficient(imf_data)

   # Use in your app
   output$imf_table <- renderDataTable({
     imf_data_processed
   })
   ```

## Key Points

1. **Year - 1 Offset**: The `Projections_from_IMF` column always shows the forecast made in the **previous year**

2. **Missing Values**: If there's no forecast from year - 1, the value will be `NA` (R) or `None` (Python)

3. **Performance**: The implementation uses efficient join operations for large datasets

4. **Flexibility**: Works with any IMF indicator (GDP, inflation, unemployment, etc.)

## Verification

The implementation has been tested and verified:

- ✓ Correctly reads from year - 1 forecast
- ✓ Handles missing previous year data (returns NA/None)
- ✓ Works with multiple years and forecast periods
- ✓ Efficient for large datasets

## Support

For questions or issues with this implementation, refer to:
- `imf_projections_simple.py` - Simplest, most readable implementation
- Run the test script to see working examples
