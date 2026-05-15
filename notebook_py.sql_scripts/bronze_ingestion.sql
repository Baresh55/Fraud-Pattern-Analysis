# SELECT CATALOG

spark.sql("USE CATALOG fraud")
spark.sql("USE SCHEMA bronze")
spark.sql("select current_catalog(),current_schema()").show()

# CUSTOMER INGESTION

from pyspark.sql.functions import current_timestamp, lit

customer_df = spark.read \
    .option("header", True) \
    .csv("s3://fraud-andrew/customer")

customer_df = customer_df.withColumn("IngestionDate", current_timestamp()) \
                         .withColumn("SourceFile", lit("s3://fraud-andrew/customer"))

customer_df.write \
    .mode("append") \
    .format("delta") \
    .saveAsTable("bronze.customer_raw")

# ACCOUNT INGESTION

from pyspark.sql.functions import current_timestamp, lit

account_df = spark.read \
    .option("header", True) \
    .csv("s3://fraud-andrew/account")

account_df.write \
    .mode("append") \
    .format("delta") \
    .saveAsTable("bronze.account_raw")

# TRANSACTION INGESTION

from pyspark.sql.functions import current_timestamp, lit

transaction_df = spark.read \
    .option("header", True) \
    .csv("s3://fraud-andrew/transaction")

transaction_df.write \
    .mode("append") \
    .format("delta") \
    .saveAsTable("bronze.transaction_raw")

