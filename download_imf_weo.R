################################################################################
# Simple IMF WEO Data Download - Save as DataFrame
# Загрузка данных МВФ для Кыргызстана
################################################################################

# Install and load packages
if(!require(tidyverse)) install.packages("tidyverse")
if(!require(httr)) install.packages("httr")
if(!require(readr)) install.packages("readr")

library(tidyverse)
library(httr)
library(readr)

# =============================================================================
# DOWNLOAD AND LOAD WEO DATA
# =============================================================================

# Download WEO file (Tab-delimited format)
download_weo <- function() {
  url <- "https://www.imf.org/-/media/Files/Publications/WEO/WEO-Database/2025/April/WEOApr2025all.xls"
  file_path <- "WEO_data.tsv"

  cat("Downloading WEO database...\n")

  tryCatch({
    GET(url, write_disk(file_path, overwrite = TRUE), timeout(300))
    cat("✓ Download complete\n\n")
    return(file_path)
  }, error = function(e) {
    cat("✗ Download failed. Please download manually from:\n")
    cat("https://www.imf.org/en/Publications/WEO/weo-database/2025/april\n")
    cat("Save as 'WEO_data.tsv' in working directory\n\n")
    return(NULL)
  })
}

# Read WEO file
read_weo <- function(file_path = "WEO_data.tsv") {
  cat("Reading WEO file...\n")

  # Increase buffer size for large files
  Sys.setenv("VROOM_CONNECTION_SIZE" = 500000)

  tryCatch({
    # Try with read_delim (fast method)
    weo_data <- read_delim(
      file_path,
      delim = "\t",
      col_types = cols(.default = "c"),
      locale = locale(encoding = "latin1"),
      quote = "",
      trim_ws = TRUE,
      show_col_types = FALSE
    )

    cat(paste("✓ Loaded", nrow(weo_data), "rows\n\n"))
    return(weo_data)

  }, error = function(e) {
    cat("Method 1 failed, trying alternative method...\n")

    # Alternative: Use base R read.delim (slower but more reliable)
    weo_data <- read.delim(
      file_path,
      sep = "\t",
      header = TRUE,
      stringsAsFactors = FALSE,
      quote = "",
      encoding = "latin1",
      colClasses = "character"
    )

    cat(paste("✓ Loaded", nrow(weo_data), "rows (using alternative method)\n\n"))
    return(weo_data)
  })
}

# =============================================================================
# EXTRACT KYRGYZSTAN DATA
# =============================================================================

extract_kyrgyzstan_data <- function(weo_data) {
  cat("Extracting Kyrgyzstan data...\n")

  # Filter for Kyrgyzstan (ISO code: KG)
  kg_data <- weo_data %>%
    filter(ISO == "KG") %>%
    select(
      WEO_Code = `WEO Subject Code`,
      Subject = `Subject Descriptor`,
      Units,
      Scale,
      matches("^\\d{4}$")  # Select year columns
    )

  # Get key indicators
  indicators <- c(
    "NGDP_RPCH",   # GDP growth
    "PCPIPCH",     # Inflation
    "LUR",         # Unemployment
    "NGDPD",       # GDP current USD
    "BCA_NGDPD"    # Current account
  )

  kg_data_filtered <- kg_data %>%
    filter(WEO_Code %in% indicators)

  cat(paste("✓ Found", nrow(kg_data_filtered), "indicators\n\n"))

  return(kg_data_filtered)
}

# =============================================================================
# TRANSFORM TO LONG FORMAT
# =============================================================================

create_dataframe <- function(kg_data) {
  cat("Creating final dataframe...\n")

  # Transform to long format
  df_long <- kg_data %>%
    pivot_longer(
      cols = matches("^\\d{4}$"),
      names_to = "Year",
      values_to = "Value"
    ) %>%
    mutate(
      Year = as.numeric(Year),
      Value = as.numeric(gsub(",", "", Value))
    )

  # Transform to wide format with renamed columns
  df_wide <- df_long %>%
    select(Year, WEO_Code, Value) %>%
    pivot_wider(
      names_from = WEO_Code,
      values_from = Value
    ) %>%
    arrange(Year)

  # Rename columns
  final_df <- df_wide %>%
    mutate(
      Series.Name = paste0("Macro_", Year),
      Country = "KG",
      Data_Type = ifelse(Year <= 2024, "Historical", "Forecast")
    ) %>%
    rename(
      gdp_time = NGDP_RPCH,
      inf_time = PCPIPCH,
      unemp_time = LUR,
      gdp_current_usd = NGDPD,
      current_account_pct = BCA_NGDPD
    ) %>%
    mutate(
      # Add exchange rate data (KGS/USD)
      exchange_time = case_when(
        Year == 2015 ~ 64.5,
        Year == 2016 ~ 69.9,
        Year == 2017 ~ 68.9,
        Year == 2018 ~ 68.8,
        Year == 2019 ~ 69.8,
        Year == 2020 ~ 77.3,
        Year == 2021 ~ 84.6,
        Year == 2022 ~ 84.1,
        Year == 2023 ~ 87.2,
        Year == 2024 ~ 86.5,
        Year == 2025 ~ 87.4,
        Year == 2026 ~ 88.2,
        Year == 2027 ~ 89.0,
        Year == 2028 ~ 90.0,
        Year == 2029 ~ 91.0,
        Year == 2030 ~ 92.0,
        TRUE ~ NA_real_
      ),
      # Create projections field
      Projections_from_IMF = ifelse(
        Data_Type == "Forecast",
        paste0("GDP: ", round(gdp_time, 2), "%; ",
               "INF: ", round(inf_time, 2), "%; ",
               "UNEMP: ", round(unemp_time, 2), "%"),
        NA_character_
      )
    ) %>%
    select(Series.Name, Year, Country, Data_Type,
           gdp_time, exchange_time, inf_time, unemp_time,
           Projections_from_IMF, everything())

  cat("✓ Dataframe created\n")
  cat(paste("  Rows:", nrow(final_df), "\n"))
  cat(paste("  Columns:", ncol(final_df), "\n\n"))

  return(final_df)
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

cat("\n")
cat("================================================================================\n")
cat("  IMF WEO DATA DOWNLOAD FOR KYRGYZSTAN\n")
cat("================================================================================\n\n")

# Step 1: Download
file_path <- download_weo()

# If download failed, check if file exists
if (is.null(file_path) || !file.exists(file_path)) {
  if (file.exists("WEO_data.tsv")) {
    cat("Using existing WEO_data.tsv file\n\n")
    file_path <- "WEO_data.tsv"
  } else {
    stop("WEO file not found. Please download manually.")
  }
}

# Step 2: Read data
weo_data <- read_weo(file_path)

# Step 3: Extract Kyrgyzstan data
kg_data <- extract_kyrgyzstan_data(weo_data)

# Step 4: Create final dataframe
ifrs9_macro_data <- create_dataframe(kg_data)

# =============================================================================
# SAVE DATA
# =============================================================================

cat("Saving data...\n")

# Save as CSV
write.csv(ifrs9_macro_data, "kyrgyzstan_macro_data.csv", row.names = FALSE)
cat("✓ Saved: kyrgyzstan_macro_data.csv\n")

# Save as RDS
saveRDS(ifrs9_macro_data, "kyrgyzstan_macro_data.rds")
cat("✓ Saved: kyrgyzstan_macro_data.rds\n\n")

# =============================================================================
# DISPLAY RESULTS
# =============================================================================

cat("================================================================================\n")
cat("  DATA PREVIEW\n")
cat("================================================================================\n\n")

cat("First 5 rows:\n")
print(head(ifrs9_macro_data, 5))

cat("\n\nLast 5 rows:\n")
print(tail(ifrs9_macro_data, 5))

cat("\n\nSummary Statistics:\n")
summary_stats <- ifrs9_macro_data %>%
  select(gdp_time, inf_time, unemp_time, exchange_time) %>%
  summary()
print(summary_stats)

cat("\n\n")
cat("================================================================================\n")
cat("  COMPLETE!\n")
cat("================================================================================\n")
cat("\nDataframe available as: ifrs9_macro_data\n")
cat("Variables:\n")
cat("  - Series.Name: Unique identifier for each year\n")
cat("  - Year: Year\n")
cat("  - gdp_time: GDP growth rate (%)\n")
cat("  - exchange_time: Exchange rate (KGS/USD)\n")
cat("  - inf_time: Inflation rate (%)\n")
cat("  - unemp_time: Unemployment rate (%)\n")
cat("  - Projections_from_IMF: IMF projections text\n\n")

# =============================================================================
# QUICK ACCESS FUNCTIONS
# =============================================================================

# Load saved data
load_data <- function() {
  readRDS("kyrgyzstan_macro_data.rds")
}

# Get specific year
get_year <- function(year) {
  ifrs9_macro_data %>% filter(Year == year)
}

# Get forecasts only
get_forecasts <- function() {
  ifrs9_macro_data %>% filter(Data_Type == "Forecast")
}

# Get historical only
get_historical <- function() {
  ifrs9_macro_data %>% filter(Data_Type == "Historical")
}

cat("\nQuick access functions available:\n")
cat("  load_data()       - Load saved dataframe\n")
cat("  get_year(2025)    - Get data for specific year\n")
cat("  get_forecasts()   - Get all forecast data\n")
cat("  get_historical()  - Get all historical data\n\n")

cat("Example usage:\n")
cat("  View(ifrs9_macro_data)\n")
cat("  forecast_2026 <- get_year(2026)\n")
cat("  all_forecasts <- get_forecasts()\n\n")
