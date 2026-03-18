# Automation Scripts

[English](README.md) | [简体中文](README_zh-CN.md)

> [!NOTE]
> This directory contains the implementation of the project's automation infrastructure. It follows a **Single Source of Truth (SSoT)** pattern where the core logic resides in POSIX shell scripts (`.sh`), with wrappers provided for Windows compatibility (`.ps1`, `.bat`).

## 1. Design & Architecture

### Overview

This component provides a suite of cross-platform scripts to manage the development lifecycle, including environment setup, dependency installation, linting, testing, and deployment.

- **Portable**: Written in POSIX-compliant shell to ensure consistency across Linux, macOS, and CI environments.
- **Robust**: Includes safety guards, atomic operations, and standardized error handling.
- **Windows Optimized**: Full delegation from CMD and PowerShell to the core logic.

### Architecture

```text
[ User / Developer / CI ]
        |
    [ Makefile ] (Convenience Entry)
        |
        v
    [ scripts/*.sh ] (Core POSIX Logic, SSoT)
    /    |      \
  /     |       \
  /      |        \
[lib/common.sh] [lib/langs/*.sh] [Windows Wrappers]
(Utils/SSoT)    (Lang Modules)    (.ps1, .bat)
```

### Design Principles

- **SSoT**: Logic is never duplicated between `.sh` and `.ps1`.
- **Auditable**: Every decision is traceable via detailed logging and exit codes.
- **Idempotent**: Scripts can be run multiple times safely without side effects.
- **Fail-Fast**: Immediate exit on error with clear diagnostics.
- **Lean**: Zero-dependency for core logic where possible (uses `sh`, `sed`, `awk`).

### Responsibilities

- **Environment Provisioning**: Installing runtimes and quality tools (`setup.sh`).
- **Dependency Management**: Standardizing installation across stacks (`install.sh`).
- **Quality Assurance**: Orchestrating linting, testing, and security audits (`verify.sh`).
- **Lifecycle Automation**: Handling commits, releases, and changelog archival.

## 2. Usage Guide

### Prerequisites

- **POSIX Shell** (Standard on Linux/macOS; Git Bash or WSL on Windows)
- **PowerShell 5.1+** (For Windows wrappers)
- **Make** (Optional, provides convenient entry points)

### Quick Start

```bash
# 1. Setup development environment
sh scripts/setup.sh

# 2. Install project dependencies
sh scripts/install.sh

# 3. Verify environment health
sh scripts/verify.sh
```

### Script Reference

| Script                 | Purpose                       | Key Modules                   |
| :--------------------- | :---------------------------- | :---------------------------- |
| `setup.sh`             | Install system-level tools    | 20+ languages (via lib/langs) |
| `install.sh`           | Install project dependencies  | pnpm, pip, pre-commit         |
| `check-env.sh`         | Validate tool versions        | Runtimes, Quality Tools       |
| `verify.sh`            | Full project verification     | env, test, lint, audit        |
| `update.sh`            | Update all tooling            | managers, hooks, deps         |
| `build.sh`             | Build project artifacts       | goreleaser, tsc, pyproject    |
| `lint.sh`              | Run linters and fixers        | pre-commit, auto-fix          |
| `test.sh`              | Execute test suites           | bats, pytest, vitest, vitest  |
| `bench.sh`             | Run performance benchmarks    | pytest-benchmark, k6          |
| `audit.sh`             | Security & vulnerability scan | gitleaks, trivy, osv-scanner  |
| `commit.sh`            | Guided conventional commit    | commitizen (cz)               |
| `release.sh`           | Standardized tagged release   | git tag (v-prefix), auto-sync |
| `docs.sh`              | Manage documentation site     | vitepress                     |
| `env.sh`               | Manage environment variables  | .env synchronization          |
| `format.sh`            | Unified code formatting       | shfmt, prettier, ruff, gofmt  |
| `cleanup.sh`           | Remove build/temp artifacts   | build, dist, cache, .venv     |
| `init-project.sh`      | Rebrand template              | placeholders, git init        |
| `archive-changelog.sh` | Archive old versions          | major version rotation        |

### Workflow Patterns

1. **Onboarding**: `setup.sh` → `install.sh` → `verify.sh`.
2. **Daily Development**: Work → `lint.sh` → `test.sh` → `commit.sh`.
3. **Continuous Integration**: `check-env.sh` → `test.sh` → `build.sh`.

### Directory Structure

- `scripts/`: Primary automation entry points.
- `scripts/lib/`: Internal core library (`common.sh`).
- `scripts/lib/langs/`: Modular language-specific logic (Sourced by `common.sh`).
- `scripts/*.ps1` & `scripts/*.bat`: Windows entry wrappers.

## 3. Operations Guide

### Pre-deployment Checklist

1. [ ] Run `sh scripts/check-env.sh` to ensure runtime parity.
2. [ ] Run `sh scripts/verify.sh` for final QA pass.
3. [ ] Run `sh scripts/audit.sh` to ensure no secrets or critical vulnerabilities.
4. [ ] Verify versioning: Run `make release` (Audits local state and syncs manifest version).

### Performance Considerations

- **Unified Dashboard**: Displays a comprehensive summary of version statuses and installation durations.
- **Caching**: Virtualenvs (`.venv`) and `node_modules` are reused across runs.

### Troubleshooting

- **Problem**: Permission Denied.
  - **Solution**: Run `chmod +x scripts/*.sh`.
- **Problem**: Windows Script Execution Failure.
  - **Solution**: Run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.
- **Problem**: 404/Network failure during download.
  - **Diagnosis**: Check if `GITHUB_PROXY` is reachable.
  - **Solution**: Configure `GITHUB_PROXY` in `scripts/lib/common.sh` or env.

### Maintenance Procedures

- **Tool Updates**: Run `sh scripts/update.sh` weekly.
- **Cache Purge**: Run `sh scripts/cleanup.sh` to reclaim disk space.

## 4. Security Considerations

### Security Model

- **Principle of Least Privilege**: Scripts install tools to `.venv` or user directory; no `sudo` required.
- **Validation**: Sub-scripts include checksum verification for external assets.
- **Secret Hygiene**: Gitleaks integration prevents accidental credential leaks.

### Best Practices

| Aspect           | Requirement                 | Implementation            |
| :--------------- | :-------------------------- | :------------------------ |
| File Permissions | Scripts must be executable  | `chmod 755 scripts/*.sh`  |
| Secret Integrity | No hardcoded keys           | Source from `.env` only   |
| Proxy Handling   | Secure download gateway     | `GITHUB_PROXY` via TLS    |
| Windows Security | Signed or restricted policy | `-ExecutionPolicy Bypass` |

## 5. Development Guide

### Code Organization

- New logic MUST be added to a new `.sh` file in `scripts/`.
- Shared utility functions MUST be placed in `scripts/lib/common.sh`.
- Variables MUST be localized using `local` inside functions.

### Contribution Requirements

1. All new scripts MUST include a `main()` function and call `parse_common_args`.
2. All new scripts MUST pass `shellcheck --shell=sh`.
3. All new scripts MUST provide `.ps1` and `.bat` wrappers for delegation.
4. Keep English/Chinese README versions in sync.

### Local Development Setup

1. Install ShellCheck: `brew install shellcheck`.
2. Install PSScriptAnalyzer (on Windows): `Install-Module -Name PSScriptAnalyzer`.
3. Run `make lint` to verify compliance.

### References

- [POSIX Standard](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)
- [ShellCheck Wiki](https://github.com/koalaman/shellcheck/wiki)
- [PowerShell Guidelines](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)
