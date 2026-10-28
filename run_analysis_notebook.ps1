$ErrorActionPreference = "Stop"

$env:PYTHONUTF8 = "1"
$env:PYTHONIOENCODING = "utf-8"

New-Item -ItemType Directory -Force -Path `
    ".jupyter_runtime", `
    ".jupyter_runtime\ipython", `
    ".jupyter_runtime\config", `
    ".jupyter_runtime\data" | Out-Null

$env:IPYTHONDIR = (Resolve-Path ".jupyter_runtime\ipython")
$env:JUPYTER_CONFIG_DIR = (Resolve-Path ".jupyter_runtime\config")
$env:JUPYTER_DATA_DIR = (Resolve-Path ".jupyter_runtime\data")

if (-not (Test-Path ".venv\Scripts\python.exe")) {
    throw "Missing .venv. Create it first or ask Codex to rebuild the Python environment."
}

if (-not (Test-Path "data\telecom\Client.csv")) {
    throw "Missing data\telecom\Client.csv. Copy Client.csv into data\telecom first."
}

if (-not (Test-Path "data\telecom\Record.csv")) {
    throw "Missing data\telecom\Record.csv. Copy Record.csv into data\telecom first."
}

& ".\.venv\Scripts\python.exe" -m jupyter nbconvert `
    --to notebook `
    --execute "final_assignment_deliverables\home_credit_final_assignment_analysis.ipynb" `
    --output "home_credit_final_assignment_analysis_executed.ipynb" `
    --output-dir "final_assignment_deliverables" `
    --ExecutePreprocessor.timeout=600
