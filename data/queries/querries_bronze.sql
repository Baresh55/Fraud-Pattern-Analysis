CREATE TABLE IF NOT EXISTS bronze.customer_raw(
  CustomerID STRING,
  CustomerName STRING,
  Country STRING,	
  RiskCategory STRING,	
  KYCStatus STRING,	
  Occupation STRING,
  EffectiveDate STRING
)
USING DELTA
LOCATION 's3://fraud-andrew/delta-customer';

COPY INTO bronze.customer_raw
FROM 's3://fraud-andrew/customer'
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true');

ALTER TABLE bronze.customer_raw 
ADD COLUMNS (
  IngestionDate TIMESTAMP, 
  SourceFile STRING
  );

UPDATE bronze.customer_raw
SET 
 IngestionDate = current_timestamp(),
 SourceFile = 's3://fraud-andrew/customer'
 WHERE IngestionDate IS NULL;
 ---------------------------------------------
 CREATE TABLE IF NOT EXISTS bronze.account_raw(
  AccountID	STRING,
  CustomerID STRING,	
  AccountType STRING,	
  Currency STRING,
  OpenDate STRING
 )
 USING DELTA
 LOCATION 's3://fraud-andrew/delta-account';

COPY INTO bronze.account_raw
FROM 's3://fraud-andrew/account'
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true');
 ---------------------------------------------
 CREATE TABLE IF NOT EXISTS bronze.transaction_raw(
  TransactionID STRING,
  CustomerID STRING,	
  AccountID STRING,	
  TransactionDate STRING,	
  Amount STRING,	
  TransactionType STRING,	
  Channel STRING,	
  DestinationCountry STRING,	
  IsFraud	STRING,
  IsLaundered STRING,
  RiskScore STRING
 )
 USING DELTA
 LOCATION 's3://fraud-andrew/delta-transaction';

COPY INTO bronze.transaction_raw
FROM 's3://fraud-andrew/transaction'
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true');



 



