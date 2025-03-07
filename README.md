# Data-Acquisition-via-API-SQL
# Weather and Population Data Processing Pipeline

## Author
Andreea Iordache

## Short Description
This project automates the retrieval, storage, and analysis of weather and population data for multiple cities. Using APIs, the script collects real-time weather conditions from **Weatherstack** and population statistics from **API Ninjas**, storing the data in an SQLite database. SQL queries are then used to analyze the data, with results exported to CSV and Excel formats.

## Prerequisites and Dependencies

### Required Software:
- R (Recommended version: 4.3.1 or later)
- SQLite

### Install Required R Packages:
Run the following command in R to install the necessary libraries:
```r
install.packages(c("httr", "jsonlite", "RSQLite", "openxlsx"))
```

### API Key Setup:
- Obtain API keys for **Weatherstack** and **API Ninjas**.
- Store them securely in environment variables:
  ```sh
  export WEATHERSTACK_API_KEY=your_api_key
  export API_NINJAS_KEY=your_api_key
  ```

## Installation and Setup Instructions

1. **Download the project files** and place them in a dedicated directory.
2. **Ensure all required dependencies are installed.**
3. **Configure API Keys** in environment variables.

## Project Structure Overview

### **Scripts**

#### `api_sql_script.R`
- Fetches weather data using the **Weatherstack API**.
- Retrieves population statistics from **API Ninjas**.
- Stores both datasets in an SQLite database (`weather_population_data.db`).
- Executes SQL queries to analyze and compare data.
- Exports processed results to CSV and Excel files.

### **Additional Files**
- **`weather_data.csv`**: Contains retrieved weather data.
- **`population_data.csv`**: Stores city population statistics.
- **`weather_population_data.db`**: SQLite database with structured tables.
- **Query result CSVs**: `query1.csv`, `query2.csv`, etc.
- **Excel File (`Andreea_Iordache_assignment1_data.xlsx`)**: Consolidated query results.

## Usage Instructions

### **Running the Script**
Run the following command in R to execute the full pipeline:
```r
source("api_sql_script.R")
```
This will:
1. Fetch real-time weather and population data.
2. Store the data in an SQLite database.
3. Execute SQL queries for analysis.
4. Export results to CSV and Excel formats.

## Output Description

- **Weather Data (`weather_data.csv`)**: Stores temperature, wind, humidity, and other weather details.
- **Population Data (`population_data.csv`)**: Contains city names, populations, and country details.
- **SQL Queries Output (`query1.csv`, etc.)**: Stores various analytical results.
- **Database (`weather_population_data.db`)**: Stores structured weather and population data.
- **Excel File (`Andreea_Iordache_assignment1_data.xlsx`)**: Aggregates all query results for easier analysis.

## Troubleshooting and FAQs

### **API Key Issues**
- Ensure your API keys for **Weatherstack** and **API Ninjas** are correctly set as environment variables.

### **Database Not Updating**
- Check if `weather_data.csv` and `population_data.csv` exist before running the script.
- Ensure R has permission to write to the directory.

## Additional Notes
- The script is **fully automated** and can be scheduled for periodic execution.
- SQLite database allows efficient long-term storage and querying of weather and population data.

---
### **Future Improvements**
- Expand to **global city coverage**.
- Enhance **data visualization** for trends and forecasts.
- Integrate **machine learning** for weather prediction.

This project provides a **comprehensive data pipeline** for weather and population analysis using **APIs, SQL, and automation**.

