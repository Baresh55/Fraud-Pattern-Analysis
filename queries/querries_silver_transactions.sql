--step1:create silver table
CREATE OR REPLACE TABLE silver.transaction_fact(
  TransactionID STRING,
  CustomerSK BIGINT,	
  AccountSK BIGINT,	
  TransactionDate DATE,	
  Amount DECIMAL (10,2),	
  TransactionType STRING,	
  Channel STRING,	
  DestinationCountry STRING,	
  IsFraud	BOOLEAN,
  IsLaundered BOOLEAN,
  RiskScore INTEGER
);
--step2: parse date first in preparation for join below (using txdate below will break ETL since its not clean)
CREATE OR REPLACE VIEW silver.transaction_stage AS
  WITH parsed AS (
SELECT 
  TransactionID,
  CustomerID,
  AccountID,
  coalesce(
    try_to_date(TransactionDate,'MM/dd/yyyy'),
    try_to_date(TransactionDate,'dd/MM/yyyy'),
    try_to_date(TransactionDate,'MMM dd yyyy')) AS TransactionDate,
  cast(regexp_replace(Amount,',','') AS DECIMAL(10,2)) AS Amount,
  TransactionType,
  Channel,
  DestinationCountry,
  IsFraud,
  IsLaundered,
  RiskScore
FROM bronze.transaction_raw 
  )
SELECT 
  parsed.TransactionID,
  silver.customer_dim.CustomerSK,
  silver.account_dim.AccountSK,
  Parsed.TransactionDate,
  parsed.Amount,
  parsed.TransactionType,
  parsed.Channel,
  parsed.DestinationCountry,
  parsed.IsFraud,
  parsed.IsLaundered,
  parsed.RiskScore
FROM parsed LEFT JOIN silver.customer_dim ON
  parsed.CustomerID = silver.customer_dim.CustomerID
  AND parsed.TransactionDate >= silver.customer_dim.StartDate --transaction occured at/after this version started
  AND (parsed.TransactionDate <= silver.customer_dim.EndDate OR silver.customer_dim.EndDate IS NULL) --transaction occured at/before version ended
  LEFT JOIN
  silver.account_dim ON 
  parsed.AccountID = silver.account_dim.AccountID;

--step3: deduplication
CREATE OR REPLACE VIEW transaction_dedup AS 
SELECT *
FROM (
  SELECT *,
  row_number() OVER(PARTITION BY TransactionID ORDER BY TransactionDate DESC) AS rn
  FROM transaction_stage
)t 
WHERE rn = 1;

--step4: merge logic
MERGE INTO silver.transaction_fact AS target
USING transaction_dedup AS source
ON target.TransactionID = source.TransactionID

WHEN MATCHED THEN UPDATE SET 
  target.CustomerSK = source.CustomerSK, --- this needs to be included
  target.AccountSK = source.AccountSK, ---this needs to be included
  target.TransactionDate = source.TransactionDate,
  target.Amount = source.Amount,
  target.TransactionType = source.TransactionType,
  target.Channel = source.Channel,
  target.DestinationCountry = source.DestinationCountry,
  target.IsFraud = source.IsFraud,
  target.IsLaundered = source.IsLaundered,
  target.RiskScore = source.RiskScore

WHEN NOT MATCHED THEN INSERT (
  TransactionID,
  CustomerSK,
  AccountSK,
  TransactionDate,
  Amount,
  TransactionType,
  Channel,
  DestinationCountry,
  IsFraud,
  IsLaundered,
  RiskScore
) VALUES (
  source.TransactionID,
  source.CustomerSK,
  source.AccountSK,
  source.TransactionDate,
  source.Amount,
  source.TransactionType,
  source.Channel,
  source.DestinationCountry,
  source.IsFraud,
  source.IsLaundered,
  source.RiskScore
);

select * from silver.transaction_fact;
