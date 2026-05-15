# Fraud-Pattern-Analysis

## Repository Structure & Components

### 1. Datasets
The repository includes the relational datasets used to replicate the banking environment:
*   `transactions-fact`: Core transactional register capturing financial movement, timestamps, amounts, channels, and geographical destinations.
*   `customer-scd2`: Slowly Changing Dimension (SCD2) tracking historical changes in customer profiles and risk parameters over time.
*   `cases-scd1`: Overwriting Dimension (SCD1) reflecting the most up-to-date status of confirmed fraud or laundering investigation cases.

### 2. Medallion Pipeline Scripts (`py.sql`)
The complete pipeline orchestration is engineered using modular pipelines integrated into a **Job**:
*   **Bronze Pipeline:** Orchestrates the raw data ingestion from AWS into the data lake platform.
*   **Silver Pipeline:** Executes schema enforcement, transformation, joins, deduplication and merge logic.
*   **Gold Pipeline:** Contains temporary analytics views, and optimized analytical datasets.

### 3. Database Queries
Native SQL optimization scripts utilized within the Delta Lakehouse to manage data transformation steps across stages:
*   **Bronze Queries:** loads raw data directly from source folders into delta tables
*   **Silver Queries:** Cleans and standardizes data, removes duplicates, and prepares it for analysis.
*   **Gold Queries:** Builds business-ready metrics like fraud rates, account risk levels, and trend insights over time.
*   **Derived Tables Script:** SQL logic used to create key features and intermediate datasets for analysis.

### 4. Machine Learning Scripts (`/ml-python-scripts`)
Python modules for building, training, and managing predictive models and their full workflow lifecycle.
*   `logistic_regression_fraud.py`: Classifies transactions as fraud or not
*   `linear_regression_risk.py`: Predicts risk score based on transaction behavior and related features.
*   `fraud_volume_forecasting.py`: Uses past trends to predict future transaction volumes and potential fraud spikes over time.

## Automation & Scheduling
The pipeline is fully automated using Databricks Jobs, which run each stage in order—Bronze, then Silver, then Gold to ensure reliable and consistent data processing on a schedule
