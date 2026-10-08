import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib
import seaborn as sns
import kagglehub
from kagglehub import KaggleDatasetAdapter
from catboost import CatBoostClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.linear_model import LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score, confusion_matrix

matplotlib.use('TkAgg', force=True)
df = kagglehub.dataset_load(
    KaggleDatasetAdapter.PANDAS,
    "pavansubhasht/ibm-hr-analytics-attrition-dataset",
    "WA_Fn-UseC_-HR-Employee-Attrition.csv"
)
df.head()
df.drop(['EmployeeCount', 'EmployeeNumber', 'Over18', 'StandardHours'], axis=1, inplace=True)
df['Attrition'] = df['Attrition'].map({'Yes': 1, 'No': 0})

X = df.drop('Attrition', axis=1)
y = df['Attrition']

# Кодируем категориальные признаки
cat_cols = X.select_dtypes(include=['object', 'string']).columns
for col in cat_cols:
    X[col] = LabelEncoder().fit_transform(X[col])

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
def print_metrics(model, model_name):
    y_pred = model.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    prec = precision_score(y_test, y_pred)
    rec = recall_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred)
    
    # Проверяем, есть ли у модели метод predict_proba (для AUC)
    if hasattr(model, 'predict_proba'):
        y_proba = model.predict_proba(X_test)[:, 1]
        auc = roc_auc_score(y_test, y_proba)
    else:
        auc = None
    
    print(f"{model_name}:")
    print(f"  Accuracy = {acc:.3f}")
    print(f"  Precision = {prec:.3f}")
    print(f"  Recall = {rec:.3f}")
    print(f"  F1 = {f1:.3f}")
    if auc is not None:
        print(f"  AUC-ROC = {auc:.3f}")
    print()
  
  # Вызов функции для каждой модели
print_metrics(lr, 'LogisticRegression')
print_metrics(dt, 'DecisionTree')
print_metrics(rf, 'RandomForest')
print_metrics(cb, 'CatBoost')

# Матрицы ошибок
fig, axes = plt.subplots(2, 2, figsize=(10, 8))
models = [(lr, 'LogReg'), (dt, 'Tree'), (rf, 'RF'), (cb, 'CatBoost')]
for ax, (m, name) in zip(axes.flat, models):
    cm = confusion_matrix(y_test, m.predict(X_test))
    sns.heatmap(cm, annot=True, fmt='d', ax=ax, cmap='Blues')
    ax.set_title(name)
plt.tight_layout()
plt.show()

# ROC-кривая для LogisticRegression
from sklearn.metrics import roc_curve
proba = lr.predict_proba(X_test)[:, 1]
fpr, tpr, _ = roc_curve(y_test, proba)
plt.plot(fpr, tpr, label=f'Logistic Regression (AUC = {roc_auc_score(y_test, proba):.3f})')
plt.plot([0, 1], [0, 1], 'k--')
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.legend()
plt.title('ROC-кривая логистической регрессии')
plt.show()

# Важность признаков
coef = lr.coef_[0]
names = X.columns
plt.figure(figsize=(10, 5))
abs_coef = np.abs(coef)
plt.barh(names[np.argsort(abs_coef)[-15:]], coef[np.argsort(abs_coef)[-15:]])
plt.xlabel('Значение коэффициента')
plt.title('15 наиболее важных признаков (логистическая регрессия)')
plt.axvline(x=0, color='black', linewidth=0.5)
plt.show()
