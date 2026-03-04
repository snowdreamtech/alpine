# snowdreamtech.init

Invoke with `/snowdreamtech.init` in any AI IDE.

## Purpose

**Initializes the project** to prepare for subsequent development. This is the first workflow to run in a fresh clone of this template.

## When to Use

- After cloning this repository as a starting point for a new project
- When setting up a new developer's machine with the project
- After major structural changes that require re-initialization

## What It Does

1. **Installs global tools** required by the development workflow:
   - `commitlint` — commit message validation
   - `markdownlint-cli2` — Markdown linting
   - `prettier` — code formatting
   - `sort-package-json` — `package.json` sorting
   - `stylelint` — CSS/SCSS linting

2. **Sets up pre-commit hooks**:
   - Installs `pre-commit` Python package
   - Runs `pre-commit install` for commit hooks
   - Runs `pre-commit install --hook-type commit-msg` for commit message hooks

3. **Validates the environment**:
   - Checks all required tools are available on `PATH`
   - Reports any missing or misconfigured tools

## Equivalent Makefile Command

```bash
make setup
```

## Manual Steps (if needed)

```bash
# Install Node.js tools
npm install -g commitlint @commitlint/cli @commitlint/config-conventional \
  markdownlint-cli2 prettier sort-package-json stylelint

# Install pre-commit
pip install pre-commit

# Setup hooks
pre-commit install
pre-commit install --hook-type commit-msg
```

## Verification

After initialization, verify everything works:

```bash
# Test pre-commit hooks
pre-commit run --all-files

# Test commit message validation
echo "feat: test" | commitlint

# Test formatting
prettier --check .
```
