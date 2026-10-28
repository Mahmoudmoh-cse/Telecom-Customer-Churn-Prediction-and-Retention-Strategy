$ErrorActionPreference = "Stop"

$outDir = Resolve-Path "final_assignment_deliverables"
$metrics = Get-Content (Join-Path $outDir "metrics.json") -Raw | ConvertFrom-Json
$insights = Get-Content (Join-Path $outDir "telecom_insights.json") -Raw | ConvertFrom-Json

$pptxPath = Join-Path $outDir "Telecom_Churn_Business_Proposal.pptx"
$pdfPath = Join-Path $outDir "Telecom_Churn_Business_Proposal.pdf"
$htmlPath = Join-Path $outDir "Telecom_Churn_Business_Proposal_print.html"
$tempDir = Join-Path $env:TEMP "telecom_churn_assignment"
$tempPptx = Join-Path $tempDir "Telecom_Churn_Business_Proposal.pptx"
$tempPdf = Join-Path $tempDir "Telecom_Churn_Business_Proposal.pdf"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
foreach ($p in @($pptxPath, $pdfPath, $tempPptx, $tempPdf)) {
    if (Test-Path $p) { Remove-Item -LiteralPath $p -Force }
}

function FmtPct($x, $digits = 1) { return ("{0:P$digits}" -f [double]$x) }
function FmtNum($x, $digits = 0) { return ("{0:N$digits}" -f [double]$x) }

$rows = FmtNum $metrics.rows
$churn = FmtPct $metrics.churn_rate
$aucLogit = FmtNum $metrics.logistic_auc 3
$aucBoost = FmtNum $metrics.gradient_boosting_auc 3
$top10 = $insights.risk_tiers | Where-Object { [double]$_.top_percent -eq 0.1 } | Select-Object -First 1
$top20 = $insights.risk_tiers | Where-Object { [double]$_.top_percent -eq 0.2 } | Select-Object -First 1
$top10Churn = FmtPct $top10.churn_rate
$top20Churn = FmtPct $top20.churn_rate
$top10Lift = FmtNum $top10.lift 2
$netValue = FmtNum $metrics.estimated_net_campaign_value 0
$recall = FmtPct $insights.recall
$precision = FmtPct $insights.precision
$mouNon = FmtNum $insights.mean_change_mou_non_churn 1
$mouChurn = FmtNum $insights.mean_change_mou_churn 1
$eqpNon = FmtNum $insights.mean_eqpdays_non_churn 0
$eqpChurn = FmtNum $insights.mean_eqpdays_churn 0
$topDrivers = ($insights.top_permutation_importance | Select-Object -First 6 | ForEach-Object { $_.feature }) -join ", "
$highAreas = ($insights.segments.area | Select-Object -First 3 | ForEach-Object { "$($_.value): $(FmtPct $_.churn_rate)" }) -join "`n"

function Add-Text {
    param($Slide, [double]$Left, [double]$Top, [double]$Width, [double]$Height, [string]$Text, [int]$Size = 18, [int]$Color = 0x222222, [switch]$Bold)
    $shape = $Slide.Shapes.AddTextbox(1, $Left, $Top, $Width, $Height)
    $shape.TextFrame.TextRange.Text = $Text
    $shape.TextFrame.TextRange.Font.Name = "Aptos"
    $shape.TextFrame.TextRange.Font.Size = $Size
    $shape.TextFrame.TextRange.Font.Color.RGB = $Color
    if ($Bold) { $shape.TextFrame.TextRange.Font.Bold = -1 }
    $shape.TextFrame.MarginLeft = 6
    $shape.TextFrame.MarginRight = 6
    $shape.TextFrame.MarginTop = 4
    $shape.TextFrame.MarginBottom = 4
    return $shape
}

function Add-Box {
    param($Slide, [double]$Left, [double]$Top, [double]$Width, [double]$Height, [string]$Text, [int]$Fill = 0xF3F6F8, [int]$Line = 0xCED8E0, [int]$Size = 17, [int]$Color = 0x222222, [switch]$Bold)
    $shape = $Slide.Shapes.AddShape(1, $Left, $Top, $Width, $Height)
    $shape.Fill.ForeColor.RGB = $Fill
    $shape.Line.ForeColor.RGB = $Line
    $shape.TextFrame.TextRange.Text = $Text
    $shape.TextFrame.TextRange.Font.Name = "Aptos"
    $shape.TextFrame.TextRange.Font.Size = $Size
    $shape.TextFrame.TextRange.Font.Color.RGB = $Color
    if ($Bold) { $shape.TextFrame.TextRange.Font.Bold = -1 }
    $shape.TextFrame.MarginLeft = 12
    $shape.TextFrame.MarginRight = 12
    $shape.TextFrame.MarginTop = 8
    $shape.TextFrame.MarginBottom = 8
    return $shape
}

function Add-Header {
    param($Slide, [string]$Title, [int]$Num)
    $Slide.Background.Fill.ForeColor.RGB = 0xFFFFFF
    $bar = $Slide.Shapes.AddShape(1, 0, 0, 960, 50)
    $bar.Fill.ForeColor.RGB = 0x14313F
    $bar.Line.Visible = 0
    Add-Text $Slide 30 11 780 28 $Title 18 0xFFFFFF -Bold | Out-Null
    Add-Text $Slide 890 14 48 20 "$Num/15" 12 0xDDEAF0 | Out-Null
}

function Add-Bullets {
    param($Slide, [string[]]$Items, [double]$Left = 58, [double]$Top = 88, [double]$Width = 545, [double]$Height = 390, [int]$Size = 18)
    $txt = ($Items | ForEach-Object { "• $_" }) -join "`r"
    $shape = Add-Text $Slide $Left $Top $Width $Height $txt $Size 0x24292F
    $shape.TextFrame.TextRange.ParagraphFormat.SpaceAfter = 7
}

function Add-Metric {
    param($Slide, [double]$Left, [double]$Top, [string]$Value, [string]$Label, [int]$Fill = 0xE9F3F5)
    Add-Box $Slide $Left $Top 165 92 "$Value`n$Label" $Fill 0x96B4BD 21 0x14313F -Bold | Out-Null
}

function Add-Bar {
    param($Slide, [double]$Left, [double]$Top, [double]$Width, [string]$Label, [double]$Value, [int]$Color = 0x2D6A7E)
    Add-Text $Slide $Left ($Top - 4) 220 24 $Label 13 0x24292F | Out-Null
    $bg = $Slide.Shapes.AddShape(1, ($Left + 230), $Top, 210, 16)
    $bg.Fill.ForeColor.RGB = 0xE6EBEF
    $bg.Line.Visible = 0
    $fg = $Slide.Shapes.AddShape(1, ($Left + 230), $Top, [Math]::Max(1, 210 * $Value), 16)
    $fg.Fill.ForeColor.RGB = $Color
    $fg.Line.Visible = 0
    Add-Text $Slide ($Left + 450) ($Top - 4) 80 24 (FmtPct $Value) 13 0x24292F | Out-Null
}

$slides = @(
    @{
        title = "AI Churn Prevention for a Telecom Operator"
        body = @(
            "Goal: predict which customers are most likely to leave and prioritize retention actions.",
            "Data: Client.csv and Record.csv joined by Customer_ID.",
            "Recommendation: use risk tiers, not a one-size-fits-all discount campaign."
        )
    },
    @{
        title = "Executive Summary"
        body = @(
            "The dataset contains $rows customers and the observed churn rate is $churn.",
            "Gradient boosting performs best with validation AUC $aucBoost.",
            "The top 10% highest-risk customers churn at $top10Churn, which is $top10Lift times the average rate.",
            "The model should drive a tiered retention program: human contact for highest risk, low-cost outreach for medium risk."
        )
    },
    @{
        title = "Dataset Used"
        body = @(
            "Client.csv contains account profile, household, handset, credit and demographic variables.",
            "Record.csv contains usage, revenue, call quality, customer care and the churn target.",
            "The two tables are merged one-to-one by Customer_ID.",
            "Target variable: churn, where 1 means the customer left."
        )
    },
    @{
        title = "Current Churn Problem"
        body = @(
            "Churn is close to one customer in two, so retention is a material revenue issue.",
            "Average monthly revenue is $(FmtNum $insights.average_monthly_revenue 1).",
            "Customers who churn show a larger decline in minutes of use: $mouChurn versus $mouNon for customers who stay.",
            "Customers who churn have older equipment on average: $eqpChurn days versus $eqpNon days."
        )
    },
    @{
        title = "Important Signals"
        body = @(
            "The strongest model signals are: $topDrivers.",
            "Usage decline is a useful warning sign before churn.",
            "Equipment age matters, suggesting handset upgrade offers may reduce churn.",
            "Some customer groups and regions have meaningfully higher churn rates."
        )
    },
    @{
        title = "Modeling Approach"
        body = @(
            "Baseline model: logistic regression with imputation, scaling and categorical encoding.",
            "Main model: histogram gradient boosting to capture nonlinear churn patterns.",
            "Validation method: stratified 80/20 train-validation split.",
            "Metric: ROC-AUC, which measures how well the model ranks churn risk."
        )
    },
    @{
        title = "Model Output"
        body = @(
            "Logistic regression AUC: $aucLogit.",
            "Gradient boosting AUC: $aucBoost.",
            "Selected model: gradient boosting.",
            "The output is a churn risk score for each customer, not an automatic decision."
        )
    },
    @{
        title = "Risk Tier Results"
        body = @(
            "Top 10% risk tier: $top10Churn churn rate, $($top10.actual_churn_customers) churn customers in validation.",
            "Top 20% risk tier: $top20Churn churn rate, $($top20.actual_churn_customers) churn customers in validation.",
            "This lift makes retention targeting more efficient than contacting customers randomly.",
            "Use top-tier scores for costly offers; use lower-cost messaging for wider groups."
        )
    },
    @{
        title = "Threshold Simulation"
        body = @(
            "A broad threshold of 0.17 captures $recall of churn cases but targets almost all customers.",
            "Precision at that threshold is $precision, close to the base churn rate.",
            "Business interpretation: the threshold is useful as an early-warning flag, not as a universal discount rule.",
            "The practical policy should be tiered by score and customer value."
        )
    },
    @{
        title = "Retention Policy"
        body = @(
            "High risk + high revenue: retention specialist call and personalized offer.",
            "High risk + old handset: upgrade or device financing offer.",
            "High risk + usage decline: proactive service check and plan review.",
            "Medium risk: low-cost SMS/app campaign; low risk: monitor only."
        )
    },
    @{
        title = "Financial Impact"
        body = @(
            "The campaign simulation estimates net value of $netValue on the validation sample.",
            "Assumptions: 25% successful retention among true churn cases, six months of retained revenue and offer cost of 10 per contacted customer.",
            "The final business case should update these assumptions with actual campaign cost and customer lifetime value.",
            "The model gives a measurable way to compare retained revenue against offer spend."
        )
    },
    @{
        title = "Operational Workflow"
        body = @(
            "1. Score customers weekly or monthly using latest usage and service data.",
            "2. Segment customers into high, medium and low churn risk.",
            "3. Match action type to risk, revenue and churn reason.",
            "4. Track acceptance, retained revenue and churn outcome for model refresh."
        )
    },
    @{
        title = "Risks And Controls"
        body = @(
            "Do not treat the score as a final customer decision.",
            "Monitor churn rate, campaign ROI, contact rate and customer complaints.",
            "Avoid training on future information after churn is already known.",
            "Retrain after new campaign outcomes are collected."
        )
    },
    @{
        title = "Quotation"
        body = @(
            "Churn scoring system implementation: 60,000.",
            "Monthly monitoring, retraining and reporting: 4,000.",
            "Optional performance fee: tied to verified retained revenue.",
            "The pricing is justified by recurring revenue protected through targeted retention."
        )
    },
    @{
        title = "Recommendation"
        body = @(
            "Adopt the gradient boosting churn score as a retention decision-support tool.",
            "Start with the top 10% to 20% risk tiers because they have the clearest lift.",
            "Use the first campaign to measure true offer cost, success rate and retained revenue.",
            "Then retrain the model and scale the program."
        )
    }
)

$htmlSections = foreach ($s in $slides) {
    $lis = ($s.body | ForEach-Object { "<li>$([System.Net.WebUtility]::HtmlEncode($_))</li>" }) -join "`n"
    "<section><h1>$([System.Net.WebUtility]::HtmlEncode($s.title))</h1><ul>$lis</ul></section>"
}
$html = @"
<!doctype html><html><head><meta charset="utf-8"><title>Telecom Churn Proposal</title>
<style>@page{size:16in 9in;margin:0}body{margin:0;font-family:Aptos,Arial,sans-serif;background:#f5f7fa;color:#17202a}section{width:16in;height:9in;box-sizing:border-box;page-break-after:always;padding:.7in .85in;background:white;position:relative}section:before{content:"";position:absolute;left:0;right:0;top:0;height:.42in;background:#14313F}h1{margin:.2in 0 .32in 0;font-size:32pt;color:#14313F}ul{font-size:21pt;line-height:1.34;max-width:13in}li{margin-bottom:.18in}</style>
</head><body>$($htmlSections -join "`n")</body></html>
"@
[System.IO.File]::WriteAllText($htmlPath, $html, [System.Text.UTF8Encoding]::new($false))

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
            $slide.Background.Fill.ForeColor.RGB = 0x14313F
            Add-Text $slide 58 72 820 78 $s.title 34 0xFFFFFF -Bold | Out-Null
            Add-Text $slide 62 172 760 90 "A data-driven retention proposal using real Client.csv and Record.csv outputs." 22 0xDDEAF0 | Out-Null
            Add-Metric $slide 70 310 $rows "customers" 0xE9F3F5
            Add-Metric $slide 275 310 $churn "churn rate" 0xF7EEE1
            Add-Metric $slide 480 310 $aucBoost "model AUC" 0xE7F1E8
            Add-Text $slide 62 476 760 26 "Final Assignment | Telecom Churn Prediction" 12 0xC7D6DD | Out-Null
        } else {
            Add-Header $slide $s.title ($i + 1)
            Add-Bullets $slide $s.body
            if ($i -eq 1) {
                Add-Metric $slide 640 95 $rows "customers" 0xE9F3F5
                Add-Metric $slide 640 205 $churn "churn rate" 0xF7EEE1
                Add-Metric $slide 640 315 $top10Churn "top 10% risk churn" 0xE7F1E8
            } elseif ($i -eq 6) {
                Add-Bar $slide 612 140 260 "Logistic regression AUC" ([double]$metrics.logistic_auc) 0x7D8FA0
                Add-Bar $slide 612 190 260 "Gradient boosting AUC" ([double]$metrics.gradient_boosting_auc) 0x2D6A7E
                Add-Box $slide 630 270 245 105 "Selected model`nGradient Boosting`nAUC $aucBoost" 0xE7F1E8 0x8BBE97 20 0x163A22 -Bold | Out-Null
            } elseif ($i -eq 7) {
                Add-Bar $slide 612 130 260 "Overall churn" ([double]$metrics.churn_rate) 0x7D8FA0
                Add-Bar $slide 612 180 260 "Top 10% risk" ([double]$top10.churn_rate) 0xC6524A
                Add-Bar $slide 612 230 260 "Top 20% risk" ([double]$top20.churn_rate) 0xD08B2E
                Add-Box $slide 630 315 245 90 "Lift in top 10%`n$top10Lift x average" 0xF7EEE1 0xD9A45D 22 0x4A3100 -Bold | Out-Null
            } elseif ($i -eq 8) {
                Add-Box $slide 628 115 250 110 "Confusion matrix`nTP $($insights.confusion_matrix.tp) | FP $($insights.confusion_matrix.fp)`nFN $($insights.confusion_matrix.fn) | TN $($insights.confusion_matrix.tn)" 0xF3F6F8 0xCED8E0 16 0x24292F | Out-Null
                Add-Box $slide 628 265 250 88 "Interpretation`nUse tiers instead of one broad discount rule." 0xE9F3F5 0x96B4BD 17 0x14313F -Bold | Out-Null
            } elseif ($i -eq 4) {
                Add-Box $slide 630 96 250 225 "Top regions by churn`n$highAreas" 0xF7EEE1 0xD9A45D 15 0x4A3100 | Out-Null
            } elseif ($i -eq 10) {
                Add-Box $slide 628 120 250 120 "Estimated net value`n$netValue" 0xE7F1E8 0x8BBE97 25 0x163A22 -Bold | Out-Null
                Add-Box $slide 628 280 250 94 "Update with real campaign cost before final pricing." 0xF3F6F8 0xCED8E0 17 0x24292F | Out-Null
            } else {
                Add-Box $slide 635 130 235 175 "Key outputs`nRows: $rows`nChurn: $churn`nAUC: $aucBoost`nTop 10%: $top10Churn" 0xF3F6F8 0xCED8E0 17 0x24292F | Out-Null
            }
        }
    }

    $presentation.SaveAs($tempPptx)
    $presentation.SaveAs($tempPdf, 32)
}
finally {
    if ($presentation -ne $null) { try { $presentation.Close() | Out-Null } catch {} }
    if ($ppt -ne $null) { try { $ppt.Quit() | Out-Null } catch {} }
}

Copy-Item -LiteralPath $tempPptx -Destination $pptxPath -Force
Copy-Item -LiteralPath $tempPdf -Destination $pdfPath -Force

Write-Output "Created improved telecom deck:"
Write-Output $pptxPath
Write-Output $pdfPath
Write-Output $htmlPath
