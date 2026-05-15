--Customer Transaction Frequency (is the customer transacting frequently)
--Average Transaction Amount (is transaction outside average)
--Country Risk Behavior (is destination unusal)
--Channel Behavior (is the customer using a new channel)
--Customer Stability(new clients likely to commit fraud)

CREATE OR REPLACE VIEW gold.Transaction_Features AS
SELECT
    silver.transaction_fact.TransactionID AS TransactionID,
    silver.customer_dim.CustomerSK AS CustomerSK,
    silver.transaction_fact.AccountSK AS AccountSK,
    silver.transaction_fact.TransactionDate AS TransactionDate,
    silver.transaction_fact.Amount AS Amount,
    silver.transaction_fact.TransactionType AS TransactionType,
    silver.transaction_fact.Channel AS Channel,
    silver.transaction_fact.DestinationCountry AS DestinationCountry,
    silver.transaction_fact.IsFraud AS IsFraud,
    silver.transaction_fact.IsLaundered AS IsLaundered,
    silver.transaction_fact.RiskScore AS RiskScore,

    -- =========================
    -- 1. Transaction Frequency
    -- =========================
    COUNT(*) OVER (
        PARTITION BY silver.customer_dim.CustomerSK --partition by each customer
        ORDER BY silver.transaction_fact.TransactionDate --in time order
        RANGE BETWEEN INTERVAL 7 DAYS PRECEDING AND CURRENT ROW --using last x no of days up to this transaction
    ) AS TxnCount_Last_7_Days,

    -- =========================
    -- 2. Average Amount (30 days)
    -- =========================
    ROUND(AVG(silver.transaction_fact.Amount) OVER (
        PARTITION BY silver.customer_dim.CustomerSK
        ORDER BY silver.transaction_fact.TransactionDate
        RANGE BETWEEN INTERVAL 30 DAYS PRECEDING AND CURRENT ROW
    ),2) AS AvgAmount_Last_30_Days,

    -- =========================
    -- 3. Amount vs Average
    -- =========================
    CASE 
        WHEN AVG(silver.transaction_fact.Amount) OVER (
            PARTITION BY silver.customer_dim.CustomerSK
            ORDER BY silver.transaction_fact.TransactionDate
            RANGE BETWEEN INTERVAL 30 DAYS PRECEDING AND CURRENT ROW
        ) = 0 THEN NULL
        ELSE silver.transaction_fact.Amount /
        AVG(silver.transaction_fact.Amount) OVER (
            PARTITION BY silver.customer_dim.CustomerSK
            ORDER BY silver.transaction_fact.TransactionDate
            RANGE BETWEEN INTERVAL 30 DAYS PRECEDING AND CURRENT ROW
        )
    END AS Amount_vs_Avg,

    -- =========================
    -- 4. Foreign Transaction Flag
    -- =========================
    CASE 
        WHEN silver.transaction_fact.DestinationCountry <> 'Uganda' THEN 1 
        ELSE 0 
    END AS IsForeignTransaction,

      -- =========================
    -- 5. Customer Tenure (SCD2)
    -- =========================
    DATEDIFF(silver.transaction_fact.TransactionDate, silver.customer_dim.StartDate) AS CustomerTenure

FROM silver.transaction_fact 
LEFT JOIN silver.customer_dim
    ON silver.transaction_fact.CustomerSK = silver.customer_dim.CustomerSK
WHERE silver.transaction_fact.CustomerSK IS NOT NULL
