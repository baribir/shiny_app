# IMF Projections Data Processing
# This script processes IMF World Economic Outlook data with year offset correction
# Projections_from_IMF column reads data from the row year - 1 forecast

library(dplyr)

#' Process IMF projections with year offset
#'
#' @param data A dataframe containing IMF forecast data with columns: year, forecast_year, value
#' @return A dataframe with Projections_from_IMF column showing year - 1 forecast
#'
#' @details
#' The Projections_from_IMF column will contain the forecast value from the previous year.
#' For example, for year 2024, it will show the forecast that was made in 2023.
process_imf_projections <- function(data) {
  # Validate input
  required_cols <- c("year", "forecast_year", "value")
  if (!all(required_cols %in% names(data))) {
    stop("Data must contain columns: year, forecast_year, value")
  }

  # Create a lookup for year - 1 forecasts
  # For each year, we want the forecast made in the previous year
  data_with_projections <- data %>%
    arrange(year, forecast_year) %>%
    group_by(year) %>%
    mutate(
      # Get the forecast from year - 1
      Projections_from_IMF = {
        prev_year_forecast <- data %>%
          filter(forecast_year == year - 1, year == !!year) %>%
          pull(value)

        if (length(prev_year_forecast) > 0) {
          prev_year_forecast[1]
        } else {
          NA_real_
        }
      }
    ) %>%
    ungroup()

  return(data_with_projections)
}

#' Alternative implementation using left join for better performance
#'
#' @param data A dataframe containing IMF forecast data with columns: year, forecast_year, value
#' @return A dataframe with Projections_from_IMF column showing year - 1 forecast
process_imf_projections_efficient <- function(data) {
  # Validate input
  required_cols <- c("year", "forecast_year", "value")
  if (!all(required_cols %in% names(data))) {
    stop("Data must contain columns: year, forecast_year, value")
  }

  # Create a mapping of year to its year-1 forecast
  projections_lookup <- data %>%
    filter(year == forecast_year + 1) %>%
    select(year, Projections_from_IMF = value, projection_forecast_year = forecast_year)

  # Join back to original data
  data_with_projections <- data %>%
    left_join(projections_lookup, by = "year") %>%
    select(-projection_forecast_year)

  return(data_with_projections)
}

#' Example usage and testing
#'
#' Creates sample IMF forecast data and demonstrates the year - 1 offset
create_sample_imf_data <- function() {
  # Sample IMF forecast data structure
  # Scenario: Each year, IMF makes forecasts for multiple future years

  imf_data <- data.frame(
    year = c(
      # Forecasts made in 2022 for years 2022-2025
      2022, 2023, 2024, 2025,
      # Forecasts made in 2023 for years 2023-2026
      2023, 2024, 2025, 2026,
      # Forecasts made in 2024 for years 2024-2027
      2024, 2025, 2026, 2027
    ),
    forecast_year = c(
      # Year when forecast was made
      2022, 2022, 2022, 2022,
      2023, 2023, 2023, 2023,
      2024, 2024, 2024, 2024
    ),
    value = c(
      # GDP growth projections (example values)
      3.2, 3.5, 3.8, 4.0,  # 2022 forecasts
      3.1, 3.6, 3.9, 4.1,  # 2023 forecasts
      3.0, 3.4, 3.7, 3.9   # 2024 forecasts
    ),
    indicator = "GDP_growth"
  )

  return(imf_data)
}

# Example demonstration
if (!interactive()) {
  cat("IMF Projections Year Offset Example\n")
  cat("====================================\n\n")

  # Create sample data
  sample_data <- create_sample_imf_data()

  cat("Original IMF Forecast Data:\n")
  print(sample_data)

  cat("\n\nProcessed Data with Projections_from_IMF (year - 1 forecast):\n")
  result <- process_imf_projections_efficient(sample_data)
  print(result)

  cat("\n\nExplanation:\n")
  cat("- For year 2024, Projections_from_IMF shows the forecast made in 2023 (forecast_year = 2023)\n")
  cat("- For year 2023, Projections_from_IMF shows the forecast made in 2022 (forecast_year = 2022)\n")
  cat("- This ensures we're looking at the previous year's projection for each year\n")
}
