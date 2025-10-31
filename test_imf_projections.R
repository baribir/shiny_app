# Test script for IMF projections year offset functionality
# This script verifies that Projections_from_IMF correctly reads from year - 1 forecast

source("imf_projections.R")

# Test 1: Basic functionality
cat("Test 1: Basic Year - 1 Offset\n")
cat("==============================\n")

test_data <- data.frame(
  year = c(2023, 2024, 2024, 2025),
  forecast_year = c(2022, 2023, 2024, 2024),
  value = c(3.5, 3.8, 4.0, 4.2),
  indicator = "GDP_growth"
)

cat("\nInput data:\n")
print(test_data)

result <- process_imf_projections_efficient(test_data)
cat("\nResult with Projections_from_IMF:\n")
print(result)

# Test 2: Verify the offset is correct
cat("\n\nTest 2: Verify Year - 1 Offset Logic\n")
cat("=====================================\n")

# For year 2024, we expect:
# - When forecast_year = 2023, that's the previous year's forecast
# - Projections_from_IMF should show this value

year_2024_data <- result %>% filter(year == 2024)
cat("\nAll forecasts for year 2024:\n")
print(year_2024_data)

cat("\n\nExpected: Projections_from_IMF should equal the value where forecast_year = 2023\n")
expected_value <- test_data %>%
  filter(year == 2024, forecast_year == 2023) %>%
  pull(value)
cat("Expected value:", expected_value, "\n")

actual_value <- year_2024_data$Projections_from_IMF[1]
cat("Actual value:", actual_value, "\n")

if (!is.na(actual_value) && actual_value == expected_value) {
  cat("\n✓ TEST PASSED: Year - 1 offset is working correctly!\n")
} else {
  cat("\n✗ TEST FAILED: Year - 1 offset not working as expected\n")
}

# Test 3: Full sample data
cat("\n\nTest 3: Full Sample IMF Data\n")
cat("=============================\n")

full_data <- create_sample_imf_data()
full_result <- process_imf_projections_efficient(full_data)

cat("\nFull results:\n")
print(full_result %>% arrange(year, forecast_year))

# Verify specific cases
cat("\n\nVerification:\n")
cat("For year 2024 (row with forecast_year = 2024):\n")
year_2024_current <- full_result %>%
  filter(year == 2024, forecast_year == 2024)
cat("Current forecast (2024):", year_2024_current$value[1], "\n")
cat("Previous year projection:", year_2024_current$Projections_from_IMF[1], "\n")

year_2024_prev <- full_data %>%
  filter(year == 2024, forecast_year == 2023) %>%
  pull(value)
cat("Expected (from 2023 forecast):", year_2024_prev, "\n")

if (year_2024_current$Projections_from_IMF[1] == year_2024_prev) {
  cat("✓ Correct: Projections_from_IMF shows year - 1 forecast\n")
} else {
  cat("✗ Error: Mismatch in year - 1 offset\n")
}
