$ErrorActionPreference = "Stop"

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw "Install Python 3.12 or later and add it to PATH."
}

python -m venv .venv
if ($LASTEXITCODE -ne 0) { throw "Could not create the Python virtual environment." }
& .\.venv\Scripts\python.exe -m pip install --upgrade pip
if ($LASTEXITCODE -ne 0) { throw "Could not upgrade pip." }
& .\.venv\Scripts\python.exe -m pip install -r src/function-app/requirements.txt
if ($LASTEXITCODE -ne 0) { throw "Could not install Function App dependencies." }
Write-Host "Environment ready. Activate it with: .\.venv\Scripts\Activate.ps1"