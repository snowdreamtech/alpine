# scripts/setup.ps1 - Project Setup Script for Windows (PowerShell)
# This script initializes the development environment without requiring 'make'.

$VENV = if ($env:VENV) { $env:VENV } else { ".venv" }
$PYTHON = if ($env:PYTHON) { $env:PYTHON } else { "python" }

Write-Host "🚀 Initializing Snowdream Tech AI IDE Template for Windows..." -ForegroundColor Blue

# 1. Node.js & pnpm Setup
Write-Host "`n[1/4] Setting up Node.js & pnpm..." -ForegroundColor Yellow
if (Get-Command corepack -ErrorAction SilentlyContinue) {
    Write-Host "Enabling corepack..."
    corepack enable
}

if (Test-Path package.json) {
    Write-Host "Installing Node.js dependencies via pnpm..."
    pnpm install
}

# 2. Python Virtual Environment Setup
Write-Host "`n[2/4] Setting up Python Virtual Environment in $VENV..." -ForegroundColor Yellow
if (-not (Test-Path $VENV)) {
    & $PYTHON -m venv $VENV
}

$VENV_BIN = if (Test-Path "$VENV\Scripts") { "$VENV\Scripts" } else { "$VENV\bin" }
$PIP = "$VENV_BIN\pip.exe"

& $PIP install --upgrade pip
if (Test-Path requirements-dev.txt) {
    Write-Host "Installing Python dev dependencies..."
    & $PIP install -r requirements-dev.txt
}

# 3. System Tools Setup (Project-Local)
Write-Host "`n[3/4] Ensuring system tools are installed locally..." -ForegroundColor Yellow
Write-Host "All tools (shellcheck, hadolint, gitleaks, etc.) are now installed via npm/pip into $VENV or node_modules."
Write-Host "This ensures version consistency across all environments."

# 4. Pre-commit Hooks Setup
Write-Host "`n[4/4] Activating pre-commit hooks..." -ForegroundColor Yellow
$PRE_COMMIT = "$VENV_BIN\pre-commit.exe"
if (Test-Path $PRE_COMMIT) {
    & $PRE_COMMIT install --hook-type pre-commit --hook-type pre-merge-commit --hook-type commit-msg
    Write-Host "Pre-commit hooks activated!" -ForegroundColor Green
}
else {
    Write-Host "⚠️ Warning: pre-commit not found in virtual environment." -ForegroundColor Red
}

Write-Host "`n✨ Setup complete!" -ForegroundColor Green
Write-Host "You can now use 'make' or call tools directly from $VENV_BIN"
