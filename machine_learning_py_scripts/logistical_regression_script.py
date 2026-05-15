# step0: select catalog and schema

spark.sql("USE CATALOG fraud")
spark.sql("USE Schema gold")
spark.sql("select current_catalog(),current_schema()").show()

# step1: Link the notebook to the experiment (Fraud-Prediction)

import mlflow
mlflow.set_experiment("/Users/andrewtwg6@gmail.com/Fraud-Prediction")

# step2: Load derived features table into a Pandas DataFrame

df = spark.table("gold.Transaction_Features").toPandas()

# step3: define independent variable -x and dependent variables -y

# predictors
X = df[["TxnCount_Last_7_Days","AvgAmount_Last_30_Days","Amount_vs_Avg","IsForeignTransaction","CustomerTenure"]]

# target
y = df["IsFraud"]

# step4: Split training and testing data

from sklearn.model_selection import train_test_split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# step5: Train the logistic regression model

from sklearn.linear_model import LogisticRegression
model = LogisticRegression(max_iter=1000)
model.fit(X_train, y_train)

# step6: define preds and probs

preds = model.predict(X_test)
probs = model.predict_proba(X_test)[:, 1]

# step7: Compares actual values with model predictions and probabilities.

import pandas as pd
pd.DataFrame({
    "Actual": y_test,
    "Predicted": preds,
    "PredictedProb": probs
}).head(10)

# step8: Save results for dashboard / SQL

import pandas as pd
logistic_df = pd.DataFrame({
    "Actual": y_test,
    "Predicted": preds,
    "PredictedProb": probs
})

spark.createDataFrame(logistic_df) \
    .write.mode("overwrite") \
    .saveAsTable("gold.fraud_predictions")

display(logistic_df.head())

#step9: Evaluate accuracy

from sklearn.metrics import accuracy_score, confusion_matrix, classification_report

print("Accuracy:", accuracy_score(y_test, preds))
print("Confusion Matrix:\n", confusion_matrix(y_test, preds))
print("Classification Report:\n", classification_report(y_test, preds))

#step10: Inspect coefficients

for feature, coef in zip(X.columns, model.coef_[0]):
    print(f"{feature}: {coef:.2f}")

