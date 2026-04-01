# Bugfix Requirements Document

## Introduction

This document defines the requirements for fixing a bug in the CI environment where Gitleaks is successfully installed during the `make setup` phase but fails to be detected during the subsequent `make check-env` verification phase. This causes the "Sync Dependabot Config" GitHub Actions workflow to fail with exit code 2.

The bug manifests in CI environments (GitHub Actions) but may not reproduce locally due to differences in PATH configuration, mise cache behavior, and binary resolution timing.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN `make setup` installs Gitleaks via `run_mise install gitleaks` in CI THEN the installation logs show "── Setting up Gitleaks (8.30.1) ──" indicating successful installation

1.2 WHEN `make check-env` subsequently runs `check_tool_version "Gitleaks" "gitleaks"` in the same CI job THEN `resolve_bin "gitleaks"` returns empty/null causing the check to report "❌ Gitleaks: Not found"

1.3 WHEN the mise cache (`_G_MISE_LS_JSON_CACHE`) is disabled (set to "{}") in `refresh_mise_cache()` THEN binary resolution falls back to slower PATH-based lookup which may fail if mise shims are not yet activated

1.4 WHEN Gitleaks is installed via mise but the mise shim directory is not in PATH or shims are not refreshed THEN `resolve_bin` cannot locate the gitleaks binary through any of its 4 lookup layers

### Expected Behavior (Correct)

2.1 WHEN `make setup` installs Gitleaks via mise THEN the mise cache SHALL be refreshed immediately after installation to ensure subsequent `resolve_bin` calls can locate the binary

2.2 WHEN `make check-env` runs after `make setup` in the same CI session THEN `resolve_bin "gitleaks"` SHALL successfully locate the gitleaks binary via mise shims, PATH, or mise metadata query

2.3 WHEN `refresh_mise_cache()` is called after tool installation THEN it SHALL populate `_G_MISE_LS_JSON_CACHE` with current mise tool metadata OR ensure alternative resolution paths (shims, PATH) are functional

2.4 WHEN Gitleaks is installed and the check-env verification runs THEN the check SHALL report "✅ Gitleaks: v8.30.1 (Active)" or similar success status

### Unchanged Behavior (Regression Prevention)

3.1 WHEN other tools (Node.js, Python, Ruby, Shellcheck, etc.) are installed via mise THEN they SHALL CONTINUE TO be detected correctly by check-env

3.2 WHEN `make check-env` runs in local development environments THEN it SHALL CONTINUE TO detect all tools correctly without regression

3.3 WHEN mise cache is disabled for network reliability reasons THEN alternative binary resolution methods (PATH lookup, mise which, filesystem search) SHALL CONTINUE TO function

3.4 WHEN `resolve_bin` is called for any tool THEN it SHALL CONTINUE TO use the 4-layer lookup strategy (local cache, system PATH, mise metadata, filesystem search) without breaking existing functionality
