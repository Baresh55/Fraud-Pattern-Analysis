--step1: create empty silver table
CREATE OR REPLACE TABLE silver.account_dim(
  AccountSK BIGINT GENERATED ALWAYS as IDENTITY,
  AccountID	STRING,
  CustomerSK BIGINT,	
  AccountType STRING,	
  Currency STRING,
  OpenDate DATE
);

--step2: create a staging view
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
silver.customer_dim.IsCurrent = true; --SINCE A/C IS SCD1, IT CAN ONLY TAKE ONE ROW PER AccountID WHICH HAS TO BE THE LATEST

--step3: deduplicate the data
CREATE OR REPLACE VIEW account_dedup AS
SELECT *
FROM (
  SELECT *,
  row_number() OVER(PARTITION BY AccountID ORDER BY OpenDate DESC) AS rn
  FROM account_stage
)
WHERE rn = 1 AND 
QualityCheck = 'ValidOpenDate';

--step4: merge logic
MERGE INTO silver.account_dim AS target
USING account_dedup AS source
ON target.AccountID = source.AccountID --WE DONT ADD target.Iscurrent here coz this is SCD1 table

WHEN MATCHED THEN UPDATE SET
  CustomerSK = source.CustomerSK, --WE ADD THIS COZ WE GENERATED IT IN CREATE silver.account_dim. NOT DOING SO WILL GENERATE NULLS
  AccountType = source.AccountType,
  Currency = source.Currency,
  OpenDate = source.OpenDate

WHEN NOT MATCHED THEN INSERT(
  AccountID, --WE DONT ADD AccountSK BECAUSE ITS AUTO GENERATED
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

select * from silver.account_dim;


