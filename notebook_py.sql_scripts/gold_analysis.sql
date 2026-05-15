# SELECT CATALOG

spark.sql("USE CATALOG fraud")
spark.sql("USE SCHEMA gold")
spark.sql("select current_catalog(),current_schema()").show()

# ANALYSIS1- LAUNDERING RATE BY ACCOUNT TYPE

spark.sql("""
          CREATE VIEW IF NOT EXISTS gold.account_type_launderingrate AS
SELECT 
 silver.account_dim.AccountType AS AccountType,
 ROUND(COUNT(silver.transaction_fact.IsLaundered)*100/SUM(COUNT(silver.transaction_fact.IsLaundered)) OVER(),2) AS LaunderingRate
FROM silver.transaction_fact
JOIN silver.account_dim ON silver.transaction_fact.AccountSK = silver.account_dim.AccountSK
GROUP BY silver.account_dim.AccountType;
          """)

# ANALYSIS2 - FRAUD RATE BY COUNTRY

spark.sql("""
        CREATE VIEW IF NOT EXISTS gold.Uganda_Fraud AS
SELECT 
  silver.customer_dim.Country AS Country,
  silver.transaction_fact.IsFraud AS IsFraud,
  ROUND(COUNT(silver.transaction_fact.IsFraud)*100.0 / SUM(COUNT(silver.transaction_fact.IsFraud)) OVER(),2) AS RiskCategoryRate
FROM silver.transaction_fact 
JOIN silver.customer_dim ON silver.transaction_fact.CustomerSK = silver.customer_dim.CustomerSK
WHERE silver.customer_dim.Country <> 'Kenya'
GROUP BY silver.customer_dim.Country,silver.transaction_fact.IsFraud;
   """)

# ANALYSIS3 - LAUNDERING RATE BY KYC STATUS

spark.sql("""
          CREATE VIEW IF NOT EXISTS gold.luandering_account AS
SELECT 
 silver.account_dim.AccountType AS AccountType,
 ROUND(COUNT(silver.transaction_fact.IsLaundered)*100/SUM(COUNT(silver.transaction_fact.IsLaundered)) OVER(),2) AS LaunderingRate,
 silver.customer_dim.KYCStatus AS KYCStatus
FROM silver.transaction_fact
JOIN silver.account_dim ON silver.transaction_fact.AccountSK = silver.account_dim.AccountSK
JOIN silver.customer_dim ON silver.account_dim.CustomerSK = silver.customer_dim.CustomerSK
GROUP BY silver.account_dim.AccountType, silver.customer_dim.KYCStatus
ORDER BY AccountType;
          """)

# ANALYSIS4 -  LAUNDERING RATE BY COUNTRY

spark.sql("""
          CREATE VIEW IF NOT EXISTS gold.Country_LaunderingRate AS
SELECT 
 silver.customer_dim.Country AS Country,
 ROUND(COUNT(silver.transaction_fact.IsLaundered)*100/SUM(COUNT(silver.transaction_fact.IsLaundered)) OVER(),2) AS LaunderingRate
FROM silver.transaction_fact
JOIN silver.customer_dim ON silver.transaction_fact.CustomerSK = silver.customer_dim.CustomerSK
GROUP BY silver.customer_dim.Country
ORDER BY Country;
          """)

# ANALYSIS5 - AVERAGE RISK SCORE BY CUSTOMER BY DAY OF THE WEEK

spark.sql("""
          CREATE VIEW IF NOT EXISTS gold.riskscore_dow AS
SELECT 
 silver.customer_dim.CustomerName AS Name,
 date_format(silver.transaction_fact.TransactionDate, 'E') AS DayOfWeek,
 ROUND(AVG(silver.transaction_fact.RiskScore)) AS AvgRiskScore
FROM silver.transaction_fact
JOIN silver.customer_dim ON silver.transaction_fact.CustomerSK = silver.customer_dim.CustomerSK
GROUP BY silver.customer_dim.CustomerName,date_format(silver.transaction_fact.TransactionDate, 'E')
ORDER BY Name,DayOfWeek;

          """)
       