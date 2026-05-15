# CREATE SILVER ACCOUNT TABLE

spark.sql("""
          CREATE OR REPLACE TABLE silver.account_dim(
  AccountSK BIGINT GENERATED ALWAYS as IDENTITY,
  AccountID	STRING,
  CustomerSK BIGINT,	
  AccountType STRING,	
  Currency STRING,
  OpenDate DATE
);
          """)

# CREATE STAGING VIEW TO TRANSFORM DATA

spark.sql("""
          CREATE OR REPLACE VIEW account_stage AS
SELECT
  AccountID,
  CustomerSK,
  AccountType,
  initcap(Currency) AS Currency,
  coalesce(
  try_to_date(OpenDate,'MM/dd/yyyy'),
  try_to_date(OpenDate,'dd/MM/yyyy'),
  try_to_date(OpenDate,'MMM dd yyyy')) AS OpenDate,
  --flag bad data
  CASE 
   WHEN coalesce(
  try_to_date(OpenDate,'MM/dd/yyyy'),
  try_to_date(OpenDate,'dd/MM/yyyy'),
  try_to_date(OpenDate,'MMM dd yyyy')) IS NULL THEN 'InvalidOpenDate' ELSE 'ValidOpenDate' END AS QualityCheck
FROM bronze.account_raw LEFT JOIN silver.customer_dim ON
bronze.account_raw.CustomerID = silver.customer_dim.CustomerID AND
silver.customer_dim.IsCurrent = true; 
          """)

# CREATE DEDUPLICATION LOGIC

spark.sql("""
          CREATE OR REPLACE VIEW account_dedup AS
SELECT *
FROM (
  SELECT *,
  row_number() OVER(PARTITION BY AccountID ORDER BY OpenDate DESC) AS rn
  FROM account_stage
)
WHERE rn = 1 AND 
QualityCheck = 'ValidOpenDate';
          """)

# CREATE SCD1 MERGE LOGIC

spark.sql("""
          MERGE INTO silver.account_dim AS target
USING account_dedup AS source
ON target.AccountID = source.AccountID

WHEN MATCHED THEN UPDATE SET
  CustomerSK = source.CustomerSK, 
  AccountType = source.AccountType,
  Currency = source.Currency,
  OpenDate = source.OpenDate

WHEN NOT MATCHED THEN INSERT(
  AccountID, 
  CustomerSK,
  AccountType,
  Currency,
  OpenDate
) 
VALUES
(
  source.AccountID,
  source.CustomerSK,
  source.AccountType,
  source.Currency,
  source.OpenDate
);
          """)