$ErrorActionPreference = "Stop"

$root = Resolve-Path "."
$outDir = Join-Path $root "final_assignment_deliverables"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$pptxPath = Join-Path $outDir "HomeCredit_AI_Business_Proposal.pptx"
$pdfPath = Join-Path $outDir "HomeCredit_AI_Business_Proposal.pdf"
$htmlPath = Join-Path $outDir "HomeCredit_AI_Business_Proposal_print.html"
$refsPath = Join-Path $outDir "references.csv"
$nbPath = Join-Path $outDir "home_credit_final_assignment_analysis.ipynb"
$readmePath = Join-Path $outDir "README.md"
$officeTempDir = Join-Path $env:TEMP "homecredit_final_assignment"
$officeTempPptx = Join-Path $officeTempDir "HomeCredit_AI_Business_Proposal.pptx"
$officeTempPdf = Join-Path $officeTempDir "HomeCredit_AI_Business_Proposal.pdf"
New-Item -ItemType Directory -Force -Path $officeTempDir | Out-Null

foreach ($generatedPath in @($pptxPath, $pdfPath, $officeTempPptx, $officeTempPdf)) {
    if (Test-Path $generatedPath) {
        Remove-Item -LiteralPath $generatedPath -Force
    }
}

function Add-TextBox {
    param(
        $Slide, [double]$Left, [double]$Top, [double]$Width, [double]$Height,
        [string]$Text, [int]$Size = 18, [int]$Color = 0x222222,
        [switch]$Bold, [int]$Align = 1
    )
    $shape = $Slide.Shapes.AddTextbox(1, $Left, $Top, $Width, $Height)
    $shape.TextFrame.TextRange.Text = $Text
    $shape.TextFrame.MarginLeft = 4
    $shape.TextFrame.MarginRight = 4
    $shape.TextFrame.MarginTop = 2
    $shape.TextFrame.MarginBottom = 2
    $shape.TextFrame.TextRange.Font.Name = "Aptos"
    $shape.TextFrame.TextRange.Font.Size = $Size
    $shape.TextFrame.TextRange.Font.Color.RGB = $Color
    if ($Bold) { $shape.TextFrame.TextRange.Font.Bold = -1 }
    $shape.TextFrame.TextRange.ParagraphFormat.Alignment = $Align
    return $shape
}

function Add-Box {
    param(
        $Slide, [double]$Left, [double]$Top, [double]$Width, [double]$Height,
        [string]$Text, [int]$Fill = 0xF4F6F8, [int]$Line = 0xD0D7DE,
        [int]$Size = 16, [int]$Color = 0x222222, [switch]$Bold
    )
    $shape = $Slide.Shapes.AddShape(1, $Left, $Top, $Width, $Height)
    $shape.Fill.ForeColor.RGB = $Fill
    $shape.Line.ForeColor.RGB = $Line
    $shape.TextFrame.TextRange.Text = $Text
    $shape.TextFrame.MarginLeft = 12
    $shape.TextFrame.MarginRight = 12
    $shape.TextFrame.MarginTop = 8
    $shape.TextFrame.MarginBottom = 8
    $shape.TextFrame.TextRange.Font.Name = "Aptos"
    $shape.TextFrame.TextRange.Font.Size = $Size
    $shape.TextFrame.TextRange.Font.Color.RGB = $Color
    if ($Bold) { $shape.TextFrame.TextRange.Font.Bold = -1 }
    return $shape
}

function Add-Header {
    param($Slide, [string]$Title, [int]$Num)
    $Slide.Background.Fill.ForeColor.RGB = 0xFFFFFF
    $bar = $Slide.Shapes.AddShape(1, 0, 0, 960, 48)
    $bar.Fill.ForeColor.RGB = 0x0B1F33
    $bar.Line.Visible = 0
    Add-TextBox $Slide 28 10 760 28 $Title 18 0xFFFFFF -Bold | Out-Null
    Add-TextBox $Slide 890 12 45 24 "$Num/15" 12 0xD6E4F0 | Out-Null
}

function Add-Bullets {
    param($Slide, [double]$Left, [double]$Top, [double]$Width, [double]$Height, [string[]]$Items, [int]$Size = 17)
    $text = ($Items | ForEach-Object { "• $_" }) -join "`r"
    $shape = Add-TextBox $Slide $Left $Top $Width $Height $text $Size 0x222222
    $shape.TextFrame.TextRange.ParagraphFormat.SpaceAfter = 6
    return $shape
}

$refs = @(
    [pscustomobject]@{Source="Home Credit Group"; Title="Home Credit Group Annual Report 2017"; URL="https://www.homecredit.net/~/media/Files/H/Home-Credit-Group/documents/reports/2018/home-credit-annual-report-2017.pdf"; Use="Client business context and scale assumptions"},
    [pscustomobject]@{Source="Kaggle"; Title="Home Credit Default Risk competition overview"; URL="https://www.kaggle.com/c/home-credit-default-risk/overview"; Use="Dataset description and target definition"},
    [pscustomobject]@{Source="Kaggle"; Title="Home Credit Default Risk data description"; URL="https://www.kaggle.com/c/home-credit-default-risk/data"; Use="Input tables and feature meanings"},
    [pscustomobject]@{Source="Japan Financial Services Agency"; Title="Financial Services Agency information on credit and consumer finance"; URL="https://www.fsa.go.jp/"; Use="Regulatory context for lending and customer protection"},
    [pscustomobject]@{Source="Bank for International Settlements"; Title="Basel framework: credit risk and probability of default concepts"; URL="https://www.bis.org/basel_framework/"; Use="Risk terminology: PD, LGD, EAD, expected loss"},
    [pscustomobject]@{Source="World Bank"; Title="Financial inclusion overview"; URL="https://www.worldbank.org/en/topic/financialinclusion/overview"; Use="Financial inclusion motivation for responsible lending"},
    [pscustomobject]@{Source="Course materials"; Title="Final assignment tutorial PDF"; URL="local:final_assignment_tutorial.pdf"; Use="Submission rules and assignment workflow"},
    [pscustomobject]@{Source="Course materials"; Title="Outstanding student sample slides"; URL="local:Sample1.pptx; local:Sample2.pptx"; Use="Benchmark for story structure and quotation slide"}
)
$refs | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $refsPath

$slides = @(
    @{
        title="Delivering Responsible AI Credit Growth for Home Credit"
        body=@("Proposal: deploy an AI credit decision support system that reduces default loss while expanding safe lending.",
               "Client issue: Home Credit needs faster, more consistent screening as consumer lending moves online and partner channels scale.",
               "Core idea: predict probability of default, set a profit-aware threshold, and create targeted offers for low-risk customers.")
        foot="Prepared for the GCI Final Assignment | Home Credit Default Risk"
    },
    @{
        title="Client Context: Growth Creates Risk Pressure"
        body=@("Home Credit provides consumer finance through retail, online, and cash-loan channels.",
               "More applications increase revenue opportunity, but manual screening becomes slower and less consistent.",
               "Credit decisions must balance three goals: approve good customers, avoid preventable defaults, and keep the process fair and explainable.")
    },
    @{
        title="Business Problem"
        body=@("Default risk directly reduces profitability through unpaid principal, recovery costs, and opportunity cost.",
               "Overly strict screening blocks profitable customers and weakens customer growth.",
               "The business needs an operating rule that converts data science output into lending action.")
    },
    @{
        title="Dataset And Target"
        body=@("Primary table: application_train.csv, one row per loan application with TARGET = 1 for payment difficulty/default.",
               "Supporting tables, if available: bureau, previous_application, POS_CASH_balance, credit_card_balance, installments_payments.",
               "Notebook deliverable computes sample size, default rate, missingness, and feature summaries automatically.")
    },
    @{
        title="EDA Insights To Use In The Proposal"
        body=@("Expected headline metrics from notebook: overall default rate, application amount distribution, income-credit ratio, and age/employment patterns.",
               "Business interpretation: single variables rarely separate defaulters cleanly, so model-based scoring is useful.",
               "Missing values are not just a cleaning issue; they may indicate thin-file customers and process gaps.")
    },
    @{
        title="Modeling Approach"
        body=@("Baseline: logistic regression with one-hot categorical encoding and median imputation.",
               "Main model: gradient boosting model such as LightGBM, XGBoost, HistGradientBoosting, or Random Forest depending on installed libraries.",
               "Evaluation: train/validation split, ROC-AUC, confusion matrix by threshold, and profit simulation.")
    },
    @{
        title="Model Performance"
        body=@("Target acceptance: AUC above the baseline and preferably around the 0.75 range seen in strong student examples.",
               "Decision metric: choose a threshold that maximizes estimated profit, not raw accuracy.",
               "Notebook output to paste here: AUC, chosen threshold, rejected high-risk count, retained low-risk count.")
    },
    @{
        title="Feature Insights"
        body=@("Likely important drivers: external credit-source scores, credit amount, annuity burden, income ratios, employment age, prior repayment behavior.",
               "Operational insight: combine model score with expert review for borderline customers.",
               "Management insight: feature importance highlights where better data collection can improve future underwriting.")
    },
    @{
        title="Proposal 1: Profit-Maximizing Screening"
        body=@("Create a Probability-of-Default score for every new application.",
               "Approve low-risk customers automatically, route medium-risk applications to manual review, and adjust or decline high-risk loans.",
               "Use the threshold selected by expected-profit simulation rather than a fixed arbitrary cutoff.")
    },
    @{
        title="Proposal 2: Low-Risk Customer Growth"
        body=@("Identify customers with very low predicted default probability for proactive offers.",
               "Use cases: larger safe loan limits, repeat-borrower campaigns, partner-store promotions, and retention offers.",
               "This turns the model from a defensive risk tool into a revenue-growth engine.")
    },
    @{
        title="Financial Impact Framework"
        body=@("Loss avoided = reduced defaults x expected exposure x loss-given-default.",
               "Revenue lift = incremental approved/upsold low-risk customers x expected margin.",
               "Operational saving = fewer manual reviews x review cost, while keeping manual checks for borderline/high-impact cases.")
    },
    @{
        title="Implementation Flow"
        body=@("1. Applicant submits loan request through online or partner channel.",
               "2. Model returns PD score and reason codes.",
               "3. Decision engine applies approve / review / adjust / decline policy.",
               "4. Outcomes are monitored monthly and used to retrain the model.")
    },
    @{
        title="Governance And Safeguards"
        body=@("Do not use the model as a black-box rejection machine.",
               "Monitor AUC, approval rate, default rate, override rate, and segment fairness monthly.",
               "Keep expert review for borderline cases, unusually large loans, and customers with sparse data.")
    },
    @{
        title="Quotation"
        body=@("AI Credit Decision System: one-time implementation fee of JPY 80 million.",
               "Monthly support: JPY 2 million for monitoring, retraining, reporting, and policy calibration.",
               "Rationale: pricing is tied to avoided credit loss, improved approval efficiency, and reusable scoring infrastructure.")
    },
    @{
        title="Recommendation"
        body=@("Adopt AI-assisted credit scoring as a decision support layer, not a replacement for all expert judgment.",
               "Start with default-risk screening, then expand to low-risk customer growth campaigns.",
               "Success target: measurable reduction in default loss, faster screening, and profitable growth among reliable customers.")
    }
)

$htmlSlides = New-Object System.Collections.Generic.List[string]
foreach ($s in $slides) {
    $items = ($s.body | ForEach-Object { "<li>$([System.Net.WebUtility]::HtmlEncode($_))</li>" }) -join "`n"
    $htmlSlides.Add("<section><h1>$([System.Net.WebUtility]::HtmlEncode($s.title))</h1><ul>$items</ul></section>")
}
$html = @"
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>HomeCredit AI Business Proposal</title>
<style>
@page { size: 16in 9in; margin: 0; }
body { margin: 0; font-family: Aptos, Arial, sans-serif; background: #f5f7fa; color: #17202a; }
section { width: 16in; height: 9in; box-sizing: border-box; page-break-after: always; padding: .7in .85in; background: white; position: relative; }
section:before { content: ""; position: absolute; left: 0; right: 0; top: 0; height: .42in; background: #0B1F33; }
h1 { margin: .2in 0 .35in 0; font-size: 34pt; color: #0B1F33; }
ul { font-size: 21pt; line-height: 1.35; max-width: 12.5in; }
li { margin-bottom: .22in; }
section:after { content: "Home Credit AI Business Proposal"; position: absolute; bottom: .25in; left: .85in; font-size: 10pt; color: #607080; }
</style>
</head>
<body>
$($htmlSlides -join "`n")
</body>
</html>
"@
Set-Content -Path $htmlPath -Encoding UTF8 -Value $html

$cells = @(
    @{cell_type="markdown"; metadata=@{}; source=@("# Home Credit Final Assignment Analysis`n", "This notebook reproduces the data analysis, modeling, threshold selection, and financial-impact numbers used in the proposal deck.`n")},
    @{cell_type="markdown"; metadata=@{}; source=@("## 1. Setup`n", "Place the course/Kaggle CSV files in `../data/` or update `DATA_DIR`.`n")},
    @{cell_type="code"; execution_count=$null; metadata=@{}; outputs=@(); source=@("import os, json, math, warnings`n", "from pathlib import Path`n", "import numpy as np`n", "import pandas as pd`n", "import matplotlib.pyplot as plt`n", "from sklearn.model_selection import train_test_split`n", "from sklearn.compose import ColumnTransformer`n", "from sklearn.pipeline import Pipeline`n", "from sklearn.impute import SimpleImputer`n", "from sklearn.preprocessing import OneHotEncoder, StandardScaler`n", "from sklearn.linear_model import LogisticRegression`n", "from sklearn.metrics import roc_auc_score, confusion_matrix, RocCurveDisplay`n", "warnings.filterwarnings('ignore')`n", "DATA_DIR = Path('../data')`n", "TRAIN_PATH = DATA_DIR / 'application_train.csv'`n")},
    @{cell_type="code"; execution_count=$null; metadata=@{}; outputs=@(); source=@("assert TRAIN_PATH.exists(), f'Missing {TRAIN_PATH}. Put application_train.csv in the data folder.'`n", "df = pd.read_csv(TRAIN_PATH)`n", "print(df.shape)`n", "display(df.head())`n")},
    @{cell_type="markdown"; metadata=@{}; source=@("## 2. Dataset Overview And EDA`n")},
    @{cell_type="code"; execution_count=$null; metadata=@{}; outputs=@(); source=@("target_rate = df['TARGET'].mean()`n", "print(f'Rows: {len(df):,}')`n", "print(f'Default / payment difficulty rate: {target_rate:.2%}')`n", "missing = df.isna().mean().sort_values(ascending=False).head(20)`n", "display(missing.to_frame('missing_rate'))`n")},
    @{cell_type="code"; execution_count=$null; metadata=@{}; outputs=@(); source=@("fig, axes = plt.subplots(1, 3, figsize=(15, 4))`n", "df['TARGET'].value_counts(normalize=True).sort_index().plot(kind='bar', ax=axes[0], title='Target distribution')`n", "df['AMT_CREDIT'].clip(upper=df['AMT_CREDIT'].quantile(.99)).hist(ax=axes[1], bins=40)`n", "axes[1].set_title('Credit amount, clipped p99')`n", "if 'AMT_INCOME_TOTAL' in df.columns:`n", "    (df['AMT_CREDIT'] / df['AMT_INCOME_TOTAL'].replace(0, np.nan)).clip(upper=10).hist(ax=axes[2], bins=40)`n", "    axes[2].set_title('Credit-to-income ratio')`n", "plt.tight_layout()`n")},
    @{cell_type="markdown"; metadata=@{}; source=@("## 3. Baseline Model`n", "This baseline is intentionally simple and transparent. Add richer feature engineering or LightGBM/XGBoost if available.`n")},
    @{cell_type="code"; execution_count=$null; metadata=@{}; outputs=@(); source=@("y = df['TARGET']`n", "X = df.drop(columns=['TARGET', 'SK_ID_CURR'], errors='ignore')`n", "num_cols = X.select_dtypes(include=['number']).columns.tolist()`n", "cat_cols = X.select_dtypes(exclude=['number']).columns.tolist()`n", "preprocess = ColumnTransformer([`n", "    ('num', Pipeline([('imputer', SimpleImputer(strategy='median')), ('scaler', StandardScaler())]), num_cols),`n", "    ('cat', Pipeline([('imputer', SimpleImputer(strategy='most_frequent')), ('onehot', OneHotEncoder(handle_unknown='ignore', min_frequency=50))]), cat_cols),`n", "])`n", "model = Pipeline([`n", "    ('preprocess', preprocess),`n", "    ('clf', LogisticRegression(max_iter=1000, class_weight='balanced', n_jobs=None))`n", "])`n", "X_train, X_valid, y_train, y_valid = train_test_split(X, y, test_size=.2, random_state=42, stratify=y)`n", "model.fit(X_train, y_train)`n", "pred = model.predict_proba(X_valid)[:, 1]`n", "auc = roc_auc_score(y_valid, pred)`n", "print(f'Validation AUC: {auc:.4f}')`n", "RocCurveDisplay.from_predictions(y_valid, pred)`n", "plt.show()`n")},
    @{cell_type="markdown"; metadata=@{}; source=@("## 4. Threshold And Business Simulation`n")},
    @{cell_type="code"; execution_count=$null; metadata=@{}; outputs=@(); source=@("valid = X_valid.copy()`n", "valid['TARGET'] = y_valid.values`n", "valid['pd_score'] = pred`n", "LGD = 0.50  # loss-given-default assumption; replace with business assumption if provided`n", "MARGIN_RATE = 0.10  # estimated interest/margin on non-defaulted exposure`n", "exposure = valid.get('AMT_CREDIT', pd.Series(np.ones(len(valid)), index=valid.index)).fillna(valid.get('AMT_CREDIT', pd.Series([1])).median())`n", "def profit_at_threshold(t):`n", "    approve = valid['pd_score'] < t`n", "    good_profit = ((valid['TARGET'] == 0) & approve) * exposure * MARGIN_RATE`n", "    bad_loss = ((valid['TARGET'] == 1) & approve) * exposure * LGD`n", "    return float(good_profit.sum() - bad_loss.sum()), int(approve.sum()), float(approve.mean())`n", "rows = []`n", "for t in np.linspace(0.02, 0.50, 49):`n", "    p, n, r = profit_at_threshold(t)`n", "    rows.append({'threshold': t, 'estimated_profit': p, 'approved_count': n, 'approval_rate': r})`n", "sim = pd.DataFrame(rows).sort_values('estimated_profit', ascending=False)`n", "display(sim.head(10))`n", "best = sim.iloc[0]`n", "print('Best threshold:', round(best.threshold, 3), 'Approval rate:', f'{best.approval_rate:.1%}')`n")},
    @{cell_type="markdown"; metadata=@{}; source=@("## 5. Export Slide Metrics`n")},
    @{cell_type="code"; execution_count=$null; metadata=@{}; outputs=@(); source=@("metrics = {`n", "    'rows': int(len(df)),`n", "    'default_rate': float(target_rate),`n", "    'validation_auc': float(auc),`n", "    'best_threshold': float(best.threshold),`n", "    'approval_rate': float(best.approval_rate),`n", "    'estimated_profit': float(best.estimated_profit),`n", "}`n", "Path('../final_assignment_deliverables').mkdir(exist_ok=True)`n", "with open('../final_assignment_deliverables/metrics.json', 'w') as f:`n", "    json.dump(metrics, f, indent=2)`n", "metrics`n")}
)
$notebook = @{cells=$cells; metadata=@{kernelspec=@{display_name="Python 3"; language="python"; name="python3"}; language_info=@{name="python"; version="3.x"}}; nbformat=4; nbformat_minor=5}
$notebookJson = $notebook | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText($nbPath, $notebookJson, [System.Text.UTF8Encoding]::new($false))

$readme = @"
# Final Assignment Deliverables

Generated files:

- `HomeCredit_AI_Business_Proposal.pptx`: 15-slide proposal deck.
- `HomeCredit_AI_Business_Proposal.pdf`: exported PDF, if PowerPoint automation succeeds.
- `HomeCredit_AI_Business_Proposal_print.html`: browser-printable backup deck.
- `home_credit_final_assignment_analysis.ipynb`: reproducible analysis notebook.
- `references.csv`: one-reference-per-row source list.

Data note:

The provided workspace did not contain the Home Credit CSV dataset. Put `application_train.csv` and any supporting Kaggle/course tables in a sibling `data/` folder, then run the notebook. Replace the deck's metric placeholders with the generated values from `metrics.json`.
"@
Set-Content -Path $readmePath -Encoding UTF8 -Value $readme

$ppt = $null
$presentation = $null
try {
    $ppt = New-Object -ComObject PowerPoint.Application
    $ppt.Visible = [Microsoft.Office.Core.MsoTriState]::msoTrue
    $ppt.DisplayAlerts = 1
    $presentation = $ppt.Presentations.Add()
    $presentation.PageSetup.SlideWidth = 960
    $presentation.PageSetup.SlideHeight = 540

    for ($i = 0; $i -lt $slides.Count; $i++) {
        $s = $slides[$i]
        $slide = $presentation.Slides.Add($i + 1, 12)
        if ($i -eq 0) {
            $slide.Background.Fill.ForeColor.RGB = 0x0B1F33
            Add-TextBox $slide 55 70 820 90 $s.title 34 0xFFFFFF -Bold | Out-Null
            Add-TextBox $slide 60 170 800 80 $s.body[0] 22 0xD6E4F0 | Out-Null
            Add-Box $slide 60 285 255 125 $s.body[1] 0x143A5A 0x2E5C7E 17 0xFFFFFF | Out-Null
            Add-Box $slide 355 285 255 125 $s.body[2] 0xF2F7FB 0x8BB3D1 17 0x0B1F33 -Bold | Out-Null
            Add-TextBox $slide 60 482 620 24 $s.foot 12 0xB7C9D9 | Out-Null
        } else {
            Add-Header $slide $s.title ($i + 1)
            Add-Bullets $slide 60 88 520 360 $s.body 18 | Out-Null
            if ($i -eq 1) {
                Add-Box $slide 625 110 245 72 "Growth" 0xEAF5FF 0x85B7DB 21 0x0B1F33 -Bold | Out-Null
                Add-Box $slide 625 212 245 72 "Risk Control" 0xFFF5E6 0xE5B363 21 0x4A3100 -Bold | Out-Null
                Add-Box $slide 625 314 245 72 "Customer Trust" 0xEAF7EF 0x82BA94 21 0x123A22 -Bold | Out-Null
            } elseif ($i -eq 5) {
                Add-Box $slide 620 100 260 70 "Data" 0xEAF5FF 0x85B7DB 19 0x0B1F33 -Bold | Out-Null
                Add-Box $slide 620 205 260 70 "PD Score" 0xFFF5E6 0xE5B363 19 0x4A3100 -Bold | Out-Null
                Add-Box $slide 620 310 260 70 "Decision Policy" 0xEAF7EF 0x82BA94 19 0x123A22 -Bold | Out-Null
            } elseif ($i -eq 10) {
                Add-Box $slide 620 92 250 82 "Avoided loss" 0xF3F7FA 0xCDD6DF 20 0x0B1F33 -Bold | Out-Null
                Add-Box $slide 620 202 250 82 "Revenue lift" 0xF3F7FA 0xCDD6DF 20 0x0B1F33 -Bold | Out-Null
                Add-Box $slide 620 312 250 82 "Efficiency gain" 0xF3F7FA 0xCDD6DF 20 0x0B1F33 -Bold | Out-Null
            } elseif ($i -eq 13) {
                Add-Box $slide 615 108 260 100 "JPY 80M`none-time" 0x0B1F33 0x0B1F33 24 0xFFFFFF -Bold | Out-Null
                Add-Box $slide 615 250 260 100 "JPY 2M / month`nsupport" 0xEAF7EF 0x82BA94 22 0x123A22 -Bold | Out-Null
            } else {
                Add-Box $slide 625 115 245 215 "Notebook metrics to paste after dataset run:`n`nAUC: ___`nThreshold: ___`nDefault rate: ___`nImpact: ___" 0xF4F6F8 0xD0D7DE 17 0x222222 | Out-Null
            }
        }
    }

    $presentation.SaveAs($officeTempPptx)
    $presentation.SaveAs($officeTempPdf, 32)
}
finally {
    if ($presentation -ne $null) {
        try { $presentation.Close() | Out-Null } catch {}
    }
    if ($ppt -ne $null) {
        try { $ppt.Quit() | Out-Null } catch {}
    }
}

Copy-Item -LiteralPath $officeTempPptx -Destination $pptxPath -Force
Copy-Item -LiteralPath $officeTempPdf -Destination $pdfPath -Force

Write-Output "Created:"
Write-Output $pptxPath
Write-Output $pdfPath
Write-Output $htmlPath
Write-Output $nbPath
Write-Output $refsPath
