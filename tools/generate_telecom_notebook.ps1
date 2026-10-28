$ErrorActionPreference = "Stop"

$outPath = "final_assignment_deliverables\home_credit_final_assignment_analysis.ipynb"
$refsPath = "final_assignment_deliverables\references.csv"

$cells = @(
    @{
        cell_type = "markdown"
        metadata = @{}
        source = @(
            "# Telecom Churn Final Assignment Analysis`n",
            "This notebook uses `Client.csv` and `Record.csv` to predict customer churn and convert the model output into a retention business proposal.`n"
        )
    },
    @{
        cell_type = "markdown"
        metadata = @{}
        source = @("## 1. Setup And Data Loading`n")
    },
    @{
        cell_type = "code"
        execution_count = $null
        metadata = @{}
        outputs = @()
        source = @(
            "import json, warnings`n",
            "from pathlib import Path`n",
            "import numpy as np`n",
            "import pandas as pd`n",
            "import matplotlib.pyplot as plt`n",
            "from sklearn.model_selection import train_test_split`n",
            "from sklearn.compose import ColumnTransformer`n",
            "from sklearn.pipeline import Pipeline`n",
            "from sklearn.impute import SimpleImputer`n",
            "from sklearn.preprocessing import OneHotEncoder, StandardScaler, OrdinalEncoder`n",
            "from sklearn.linear_model import LogisticRegression`n",
            "from sklearn.ensemble import HistGradientBoostingClassifier`n",
            "from sklearn.metrics import roc_auc_score, confusion_matrix, classification_report, RocCurveDisplay`n",
            "warnings.filterwarnings('ignore')`n",
            "`n",
            "CLIENT_PATHS = [Path('data/telecom/Client.csv'), Path('../data/telecom/Client.csv'), Path('Client.csv')]`n",
            "RECORD_PATHS = [Path('data/telecom/Record.csv'), Path('../data/telecom/Record.csv'), Path('Record.csv')]`n",
            "CLIENT_PATH = next((p for p in CLIENT_PATHS if p.exists()), None)`n",
            "RECORD_PATH = next((p for p in RECORD_PATHS if p.exists()), None)`n",
            "assert CLIENT_PATH is not None, 'Missing Client.csv. Expected data/telecom/Client.csv'`n",
            "assert RECORD_PATH is not None, 'Missing Record.csv. Expected data/telecom/Record.csv'`n",
            "print('Client:', CLIENT_PATH)`n",
            "print('Record:', RECORD_PATH)`n"
        )
    },
    @{
        cell_type = "code"
        execution_count = $null
        metadata = @{}
        outputs = @()
        source = @(
            "client = pd.read_csv(CLIENT_PATH)`n",
            "record = pd.read_csv(RECORD_PATH)`n",
            "print('Client shape:', client.shape)`n",
            "print('Record shape:', record.shape)`n",
            "df = record.merge(client, on='Customer_ID', how='left', validate='one_to_one')`n",
            "print('Merged shape:', df.shape)`n",
            "display(df.head())`n"
        )
    },
    @{
        cell_type = "markdown"
        metadata = @{}
        source = @("## 2. Business-Focused EDA`n")
    },
    @{
        cell_type = "code"
        execution_count = $null
        metadata = @{}
        outputs = @()
        source = @(
            "target_rate = df['churn'].mean()`n",
            "print(f'Customers: {len(df):,}')`n",
            "print(f'Churn rate: {target_rate:.2%}')`n",
            "avg_monthly_revenue = pd.to_numeric(df['rev_Mean'], errors='coerce').mean()`n",
            "print(f'Average monthly revenue: {avg_monthly_revenue:.2f}')`n",
            "missing = df.isna().mean().sort_values(ascending=False).head(15)`n",
            "display(missing.to_frame('missing_rate'))`n"
        )
    },
    @{
        cell_type = "code"
        execution_count = $null
        metadata = @{}
        outputs = @()
        source = @(
            "fig, axes = plt.subplots(1, 3, figsize=(15, 4))`n",
            "df['churn'].value_counts(normalize=True).sort_index().plot(kind='bar', ax=axes[0], title='Churn distribution')`n",
            "pd.to_numeric(df['rev_Mean'], errors='coerce').clip(upper=df['rev_Mean'].quantile(.99)).hist(ax=axes[1], bins=40)`n",
            "axes[1].set_title('Monthly revenue, clipped p99')`n",
            "pd.to_numeric(df['change_mou'], errors='coerce').clip(lower=df['change_mou'].quantile(.01), upper=df['change_mou'].quantile(.99)).hist(ax=axes[2], bins=40)`n",
            "axes[2].set_title('Change in minutes of use')`n",
            "plt.tight_layout()`n"
        )
    },
    @{
        cell_type = "markdown"
        metadata = @{}
        source = @("## 3. Modeling`n", "We train a transparent logistic-regression baseline and a stronger gradient-boosting model. The target is `churn`.`n")
    },
    @{
        cell_type = "code"
        execution_count = $null
        metadata = @{}
        outputs = @()
        source = @(
            "y = df['churn'].astype(int)`n",
            "X = df.drop(columns=['churn', 'Customer_ID'], errors='ignore')`n",
            "for col in X.columns:`n",
            "    converted = pd.to_numeric(X[col], errors='coerce')`n",
            "    if converted.notna().sum() > 0:`n",
            "        X[col] = converted`n",
            "num_cols = X.select_dtypes(include=['number']).columns.tolist()`n",
            "cat_cols = X.select_dtypes(exclude=['number']).columns.tolist()`n",
            "X_train, X_valid, y_train, y_valid = train_test_split(X, y, test_size=.2, random_state=42, stratify=y)`n",
            "print('Numeric columns:', len(num_cols), 'Categorical columns:', len(cat_cols))`n",
            "`n",
            "logit_preprocess = ColumnTransformer([`n",
            "    ('num', Pipeline([('imputer', SimpleImputer(strategy='median')), ('scaler', StandardScaler())]), num_cols),`n",
            "    ('cat', Pipeline([('imputer', SimpleImputer(strategy='most_frequent')), ('onehot', OneHotEncoder(handle_unknown='ignore', min_frequency=50))]), cat_cols),`n",
            "])`n",
            "logit = Pipeline([`n",
            "    ('preprocess', logit_preprocess),`n",
            "    ('clf', LogisticRegression(max_iter=800, class_weight='balanced'))`n",
            "])`n",
            "logit.fit(X_train, y_train)`n",
            "pred_logit = logit.predict_proba(X_valid)[:, 1]`n",
            "auc_logit = roc_auc_score(y_valid, pred_logit)`n",
            "print(f'Logistic regression AUC: {auc_logit:.4f}')`n"
        )
    },
    @{
        cell_type = "code"
        execution_count = $null
        metadata = @{}
        outputs = @()
        source = @(
            "hgb_preprocess = ColumnTransformer([`n",
            "    ('num', SimpleImputer(strategy='median'), num_cols),`n",
            "    ('cat', Pipeline([`n",
            "        ('imputer', SimpleImputer(strategy='most_frequent')),`n",
            "        ('ordinal', OrdinalEncoder(handle_unknown='use_encoded_value', unknown_value=-1))`n",
            "    ]), cat_cols),`n",
            "])`n",
            "hgb = Pipeline([`n",
            "    ('preprocess', hgb_preprocess),`n",
            "    ('clf', HistGradientBoostingClassifier(max_iter=150, learning_rate=0.06, max_leaf_nodes=31, random_state=42))`n",
            "])`n",
            "hgb.fit(X_train, y_train)`n",
            "pred_hgb = hgb.predict_proba(X_valid)[:, 1]`n",
            "auc_hgb = roc_auc_score(y_valid, pred_hgb)`n",
            "print(f'Gradient boosting AUC: {auc_hgb:.4f}')`n",
            "best_model_name = 'Gradient Boosting' if auc_hgb >= auc_logit else 'Logistic Regression'`n",
            "best_pred = pred_hgb if auc_hgb >= auc_logit else pred_logit`n",
            "best_auc = max(auc_hgb, auc_logit)`n",
            "print('Selected model:', best_model_name, f'AUC={best_auc:.4f}')`n",
            "RocCurveDisplay.from_predictions(y_valid, best_pred)`n",
            "plt.show()`n"
        )
    },
    @{
        cell_type = "markdown"
        metadata = @{}
        source = @("## 4. Retention Campaign Simulation`n", "We estimate the economics of targeting high-risk customers with a retention offer.`n")
    },
    @{
        cell_type = "code"
        execution_count = $null
        metadata = @{}
        outputs = @()
        source = @(
            "valid = X_valid.copy()`n",
            "valid['churn'] = y_valid.values`n",
            "valid['churn_score'] = best_pred`n",
            "monthly_revenue = pd.to_numeric(valid['rev_Mean'], errors='coerce').fillna(pd.to_numeric(df['rev_Mean'], errors='coerce').median())`n",
            "RETENTION_MONTHS = 6`n",
            "RETENTION_SUCCESS_RATE = 0.25`n",
            "OFFER_COST = 10.0`n",
            "`n",
            "def campaign_value(threshold):`n",
            "    targeted = valid['churn_score'] >= threshold`n",
            "    saved_value = ((valid['churn'] == 1) & targeted) * monthly_revenue * RETENTION_MONTHS * RETENTION_SUCCESS_RATE`n",
            "    cost = targeted * OFFER_COST`n",
            "    return float(saved_value.sum() - cost.sum()), int(targeted.sum()), float(targeted.mean()), int(((valid['churn'] == 1) & targeted).sum())`n",
            "`n",
            "rows = []`n",
            "for t in np.linspace(0.05, 0.95, 91):`n",
            "    value, n_targeted, target_rate_at_t, captured_churners = campaign_value(t)`n",
            "    rows.append({'threshold': t, 'net_value': value, 'targeted_customers': n_targeted, 'targeted_rate': target_rate_at_t, 'captured_churners': captured_churners})`n",
            "sim = pd.DataFrame(rows).sort_values('net_value', ascending=False)`n",
            "display(sim.head(10))`n",
            "best = sim.iloc[0]`n",
            "print('Best threshold:', round(best.threshold, 2))`n",
            "print('Targeted customers:', int(best.targeted_customers), f'({best.targeted_rate:.1%} of validation customers)')`n",
            "print('Captured churners:', int(best.captured_churners))`n",
            "print('Estimated net campaign value:', round(best.net_value, 2))`n"
        )
    },
    @{
        cell_type = "markdown"
        metadata = @{}
        source = @("## 5. Management Interpretation`n")
    },
    @{
        cell_type = "code"
        execution_count = $null
        metadata = @{}
        outputs = @()
        source = @(
            "threshold = float(best.threshold)`n",
            "pred_label = (best_pred >= threshold).astype(int)`n",
            "print(confusion_matrix(y_valid, pred_label))`n",
            "print(classification_report(y_valid, pred_label, digits=3))`n",
            "print('Business reading: target the highest churn-risk customers first, especially customers with falling usage, high service issues, or high revenue at risk.')`n"
        )
    },
    @{
        cell_type = "code"
        execution_count = $null
        metadata = @{}
        outputs = @()
        source = @(
            "metrics = {`n",
            "    'dataset': 'telecom churn',`n",
            "    'rows': int(len(df)),`n",
            "    'churn_rate': float(target_rate),`n",
            "    'logistic_auc': float(auc_logit),`n",
            "    'gradient_boosting_auc': float(auc_hgb),`n",
            "    'selected_model': best_model_name,`n",
            "    'selected_auc': float(best_auc),`n",
            "    'best_campaign_threshold': float(best.threshold),`n",
            "    'targeted_rate': float(best.targeted_rate),`n",
            "    'captured_churners': int(best.captured_churners),`n",
            "    'estimated_net_campaign_value': float(best.net_value),`n",
            "}`n",
            "output_dir = Path.cwd() if Path.cwd().name == 'final_assignment_deliverables' else Path('final_assignment_deliverables')`n",
            "output_dir.mkdir(exist_ok=True)`n",
            "with open(output_dir / 'metrics.json', 'w') as f:`n",
            "    json.dump(metrics, f, indent=2)`n",
            "metrics`n"
        )
    }
)

$notebook = @{
    cells = $cells
    metadata = @{
        kernelspec = @{ display_name = "Python 3"; language = "python"; name = "python3" }
        language_info = @{ name = "python"; version = "3.x" }
    }
    nbformat = 4
    nbformat_minor = 5
}

$json = $notebook | ConvertTo-Json -Depth 30
[System.IO.File]::WriteAllText((Resolve-Path $outPath), $json, [System.Text.UTF8Encoding]::new($false))

$refs = @(
    [pscustomobject]@{Source="Assignment dataset"; Title="Telecom Client.csv"; URL="local:data/telecom/Client.csv"; Use="Customer demographics, account profile, handset and household variables"},
    [pscustomobject]@{Source="Assignment dataset"; Title="Telecom Record.csv"; URL="local:data/telecom/Record.csv"; Use="Usage, revenue, call-quality, customer-care and churn target variables"},
    [pscustomobject]@{Source="Business concept"; Title="Customer churn prediction"; URL="https://en.wikipedia.org/wiki/Customer_attrition"; Use="Definition and business framing for churn/attrition"},
    [pscustomobject]@{Source="Model evaluation"; Title="ROC curve and AUC"; URL="https://scikit-learn.org/stable/modules/model_evaluation.html#roc-metrics"; Use="AUC metric definition and evaluation framing"},
    [pscustomobject]@{Source="Implementation"; Title="scikit-learn user guide"; URL="https://scikit-learn.org/stable/user_guide.html"; Use="Preprocessing, logistic regression, and gradient boosting implementation"}
)
$refs | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $refsPath

Write-Output "Generated telecom notebook and references."
