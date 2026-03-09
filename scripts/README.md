# Automation Scripts

> [!NOTE]
> This directory contains the implementation of the project's automation infrastructure. It follows a **Single Source of Truth (SSoT)** pattern where the core logic resides in POSIX shell scripts (`.sh`), with wrappers provided for Windows compatibility (`.ps1`, `.bat`).

## 1. Design & Architecture

### Overview

This component provides a suite of cross-platform scripts to manage the development lifecycle, including environment setup, dependency installation, linting, testing, and deployment.

- **Portable**: Written in POSIX-compliant shell to ensure consistency across Linux, macOS, and CI environments.
- **Robust**: Includes safety guards, atomic operations, and standardized error handling.
- **Windows Optimized**: Full delegation from CMD and PowerShell to the core logic.

### Design Principles

- **SSoT**: Logic is never duplicated between `.sh` and `.ps1`.
- **Idempotent**: Scripts can be run multiple times safely.
- **Fail-Fast**: Immediate exit on error with clear diagnostics.

## 2. Usage Guide

### Prerequisites

- **POSIX Shell** (standard on Linux/macOS; Git Bash or WSL on Windows)
- **PowerShell 5.1+** (for Windows wrappers)
- **Make** (optional, provides convenient entry points)

### Quick Start

```bash
# Setup development environment
sh scripts/setup.sh

# Verify environment health
sh scripts/verify.sh
```

### Script Reference

| Script                 | Purpose                      | Key Modules                  |
| :--------------------- | :--------------------------- | :--------------------------- |
| `setup.sh`             | Install system-level tools   | node, python, go, rust, etc. |
| `install.sh`           | Install project dependencies | pnpm, pip, pre-commit        |
| `check-env.sh`         | Validate tool versions       | Runtimes, Quality Tools      |
| `verify.sh`            | Full project verification    | env, test, lint, audit       |
| `update.sh`            | Update all tooling           | managers, hooks, deps        |
| `init-project.sh`      | Rebrand template             | placeholders, git init       |
| `archive-changelog.sh` | Archive old versions         | major version rotation       |

## 3. Operations Guide

### Troubleshooting

- **Permission Denied**: Run `chmod +x scripts/*.sh`.
- **Windows Script Execution**: If `.ps1` fails, run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`.
- **Killed (Exit 137)**: Usually indicates a corrupted binary. Run `rm .venv/bin/<tool>` and re-run setup.

## 4. Security Considerations

- **No Sudo Requirement**: Most scripts install tools into the project-local `.venv/bin` or user-local directories.
- **Checksum Logic**: Installation functions verify binary existence and basic functionality.
- **Gitleaks Integration**: `audit.sh` and `hooks` ensure no secrets are committed.

## 5. Development Guide

### Adding New Scripts

1. Create the POSIX logic in `scripts/my-script.sh`.
2. Source `scripts/lib/common.sh`.
3. Use `guard_project_root` and `parse_common_args`.
4. Create `.ps1` and `.bat` wrappers following the delegation template in `.agent/rules/shell.md`.

### Library Usage

The `scripts/lib/common.sh` provides:

- `log_info`, `log_success`, `log_warn`, `log_error`: Colored logging.
- `download_url`: Robust downloading with retries.
- `atomic_swap`: Secure file replacement.
- `check_update_cooldown`: 24h throttling for heavy tasks.
