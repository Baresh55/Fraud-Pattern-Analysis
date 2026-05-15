# step0: select catalog and schema

spark.sql("USE CATALOG fraud")
spark.sql("USE Schema gold")
spark.sql("select current_catalog(),current_schema()").show()

# step1: import mlflow and link experiment to notebook

import mlflow
mlflow.set_experiment('/Users/andrewtwg6@gmail.com/regression_prediction')

# step2: load derived features table into pandas dataframe
df = spark.table("gold.Transaction_Features").toPandas()

# step3: define variables and train the linear regression model

from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression

X = df[["TxnCount_Last_7_Days","AvgAmount_Last_30_Days","Amount_vs_Avg","IsForeignTransaction","CustomerTenure"]]
y = df["RiskScore"]

X_train, X_test, y_train, y_test = train_test_split(X,y,test_size=0.2)

model = LinearRegression()
model.fit(X_train,y_train)

# step4: Evaluate the model & save output

predictions = model.predict(X_test)

import pandas as pd

linear_df = pd.DataFrame({
    "ActualRiskScore": y_test,
    "PredictedRiskScore": predictions
})

display(linear_df.head(10))

# step5: save output for dashboard using SQL

spark.createDataFrame(linear_df) \
    .write.mode("overwrite") \
    .saveAsTable("gold.risk_score_predictions")

# step6: display coefficients

# Show which features drive riskscore
for feature, coef in zip(X.columns, model.coef_):
    print(f"{feature}: {coef:.2f}")

# Show intercept
print(f"Intercept: {model.intercept_:.2f}")

# step7: log results + model with mlflow

import mlflow
import mlflow.sklearn
from sklearn.metrics import r2_score

with mlflow.start_run():
    mlflow.log_metric("r2", r2_score(y_test, predictions))
    mlflow.sklearn.log_model(model, "model")

