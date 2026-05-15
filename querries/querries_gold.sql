
CREATE VIEW IF NOT EXISTS gold.account_type_launderingrate AS
SELECT 
 silver.account_dim.AccountType AS AccountType,
 ROUND(COUNT(silver.transaction_fact.IsLaundered)*100/SUM(COUNT(silver.transaction_fact.IsLaundered)) OVER(),2) AS LaunderingRate
FROM silver.transaction_fact
JOIN silver.account_dim ON silver.transaction_fact.AccountSK = silver.account_dim.AccountSK
GROUP BY silver.account_dim.AccountType;
--------------------------------------------
CREATE VIEW IF NOT EXISTS gold.Uganda_Fraud AS
SELECT 
  silver.customer_dim.Country AS Country,
  silver.transaction_fact.IsFraud AS IsFraud,
  ROUND(COUNT(silver.transaction_fact.IsFraud)*100.0 / SUM(COUNT(silver.transaction_fact.IsFraud)) OVER(),2) AS RiskCategoryRate
FROM silver.transaction_fact 
JOIN silver.customer_dim ON silver.transaction_fact.CustomerSK = silver.customer_dim.CustomerSK
WHERE silver.customer_dim.Country <> 'Kenya'
GROUP BY silver.customer_dim.Country,silver.transaction_fact.IsFraud;
--------------------------------------------
CREATE VIEW IF NOT EXISTS gold.luandering_channel AS
SELECT 
 silver.transaction_fact.Channel AS Channel,
 ROUND(COUNT(silver.transaction_fact.IsLaundered)*100/SUM(COUNT(silver.transaction_fact.IsLaundered)) OVER(),2) AS LaunderingRate,
 silver.customer_dim.KYCStatus AS KYCStatus
FROM silver.transaction_fact JOIN silver.customer_dim ON
silver.transaction_fact.CustomerSK = silver.customer_dim.CustomerSK
GROUP BY silver.customer_dim.KYCStatus,silver.transaction_fact.Channel
ORDER BY Channel;
--------------------------------------------
CREATE VIEW IF NOT EXISTS gold.Country_FraudVol AS
SELECT 
 silver.customer_dim.Country AS Country,
 silver.transaction_fact.IsFraud AS IsFraud,
 COUNT(silver.transaction_fact.IsFraud) AS FraudCount
FROM silver.transaction_fact
JOIN silver.customer_dim ON silver.transaction_fact.CustomerSK = silver.customer_dim.CustomerSK
GROUP BY silver.customer_dim.Country,silver.transaction_fact.IsFraud
ORDER BY Country;
-----------------------------------------------
--average risk score by customer name by day of the week
CREATE VIEW IF NOT EXISTS gold.riskscore_dow AS
SELECT 
 silver.customer_dim.CustomerName AS Name,
 date_format(silver.transaction_fact.TransactionDate, 'E') AS DayOfWeek,
 ROUND(AVG(silver.transaction_fact.RiskScore)) AS AvgRiskScore
FROM silver.transaction_fact
JOIN silver.customer_dim ON silver.transaction_fact.CustomerSK = silver.customer_dim.CustomerSK
GROUP BY silver.customer_dim.CustomerName,date_format(silver.transaction_fact.TransactionDate, 'E')
ORDER BY Name,DayOfWeek;


