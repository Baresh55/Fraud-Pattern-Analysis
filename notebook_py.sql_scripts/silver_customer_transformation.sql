# SELECT CATALOG

spark.sql("USE CATALOG fraud")
spark.sql("USE SCHEMA silver")
spark.sql("select current_catalog(),current_schema()").show()

# CREATE SILVER TABLE

spark.sql("""
          CREATE OR REPLACE TABLE silver.customer_dim(
  CustomerSK BIGINT GENERATED ALWAYS AS IDENTITY,
  CustomerID STRING,
  CustomerName STRING,
  Country STRING,	
  RiskCategory STRING,	
  KYCStatus STRING,	
  Occupation STRING,
  StartDate DATE,
  EndDate DATE,
  IsCurrent BOOLEAN
);
          """)

#CREATE STAGING VIEW

spark.sql("""
          CREATE OR REPLACE VIEW customer_staging AS
SELECT 
  CustomerID,
  regexp_replace(CustomerName,'@','') AS CustomerName,
  initcap(trim(Country)) AS Country,
  RiskCategory,
  KYCStatus,
  Occupation,
  coalesce(
    try_to_date(trim(EffectiveDate),'MM/dd/yyyy'),
    try_to_date(trim(EffectiveDate),'dd/MM/yyyy'),
    try_to_date(trim(EffectiveDate),'yyyy-MM-dd')) AS EffectiveDate,
  IngestionDate,
  CASE 
   WHEN coalesce(
    try_to_date(trim(EffectiveDate),'MM/dd/yyyy'),
    try_to_date(trim(EffectiveDate),'dd/MM/yyyy'),
    try_to_date(trim(EffectiveDate),'yyyy-MM-dd')) IS NULL then 'InvalidEffectiveDate' ELSE 'ValidDate' END AS QualityCheck
  FROM bronze.customer_raw;

          """)

#DEDUPLICATION LOGIC

spark.sql("""
          CREATE OR REPLACE VIEW customer_dedup AS
  SELECT *
  FROM (
    SELECT *,
    row_number() OVER(PARTITION BY CustomerID ORDER BY IngestionDate DESC)AS rn
    FROM customer_staging
  )
  WHERE rn = 1 AND
  QualityCheck = 'ValidDate';
          """)

# SCD2 MERGE LOGIC

spark.sql("""
          MERGE INTO silver.customer_dim AS target
  USING customer_dedup AS source
  ON target.CustomerID = source.CustomerID AND
  target.IsCurrent = true

  WHEN MATCHED AND (
    target.CustomerName <>source.CustomerName OR 
    target.Country <>source.Country OR 
    target.RiskCategory <>source.RiskCategory OR 
    target.KYCStatus <>source.KYCStatus OR 
    target.Occupation <>source.Occupation
  )
  THEN UPDATE SET
   target.EndDate = source.EffectiveDate,
   target.IsCurrent = false;
          """)

spark.sql("""
          INSERT INTO silver.customer_dim(
CustomerID,
CustomerName,
Country,
RiskCategory,
KYCStatus,
Occupation,
StartDate,
EndDate,
IsCurrent
)
 SELECT 
 source.CustomerID,
 source.CustomerName,
 source.Country,
 source.RiskCategory,
 source.KYCStatus,
 source.Occupation,
 source.EffectiveDate,
 null,
 true
FROM customer_dedup AS source
LEFT JOIN
silver.customer_dim AS target ON 
source.CustomerID = target.CustomerID AND
target.IsCurrent = true
WHERE target.CustomerID IS NULL
OR(
  target.CustomerName <>source.CustomerName OR 
  target.Country <>source.Country OR 
  target.RiskCategory <>source.RiskCategory OR 
  target.KYCStatus <>source.KYCStatus OR 
  target.Occupation <>source.Occupation
);
          """)