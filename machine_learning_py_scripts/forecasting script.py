# step0: select catalog and schema

spark.sql("USE CATALOG fraud")
spark.sql("USE SCHEMA gold")
spark.sql("SELECT current_catalog(),current_schema()").show()

# step1: Load data from Gold table

df = spark.table("gold.Transaction_Features")
display(df)

# step2: Identify schema

df.printSchema()


# step3: Aggregate fraud volume over time

from pyspark.sql.functions import count, when, col, to_date

fraud_ts = df.withColumn("Date", to_date("TransactionDate")) \
    .groupBy("Date") \
    .agg(count(when(col("IsFraud") == True, 1)).alias("FraudVolume")) \
    .orderBy("Date")

# step4: convert to pandas(required for forecasting models)

pdf = fraud_ts.toPandas()
pdf = pdf.sort_values("Date")


# step5: visualize output
import matplotlib.pyplot as plt

plt.plot(pdf["Date"], pdf["FraudVolume"])
plt.title("Fraud Volume Over Time")
plt.xlabel("Date")
plt.ylabel("Fraud Count")
plt.show()

# step6: Create time-based features(We convert it into ML format)

pdf["DayIndex"] = range(len(pdf))

# step7: Train forecasting model (simple baseline)

# Start with Linear Regression
from sklearn.linear_model import LinearRegression

X = pdf[["DayIndex"]]
y = pdf["FraudVolume"]

model = LinearRegression()
model.fit(X, y)

# step8: Make predictions

pdf["Predicted"] = model.predict(X)
display(pdf)

# step9: Plot actual vs predicted trend

# import matplotlib
import matplotlib.pyplot as plt

plt.plot(pdf["Date"], pdf["FraudVolume"], label="Actual")
plt.plot(pdf["Date"], pdf["Predicted"], label="Predicted")
plt.legend()
plt.title("Fraud Volume Forecast (Baseline)")
plt.show()

# step10: Save output to gold table

spark.createDataFrame(pdf) \
    .write.mode("overwrite") \
    .saveAsTable("gold.fraud_forecast")

# step11: Log everything in MLflow
import mlflow
import mlflow.sklearn

with mlflow.start_run():
    mlflow.log_metric("r2", model.score(X, y))
    mlflow.sklearn.log_model(model, "fraud_forecast_model")
