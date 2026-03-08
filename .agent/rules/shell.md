# Shell Scripting Guidelines

> Objective: Define standards for writing robust, portable, and safe shell scripts for automation, CI/CD pipelines, and developer tooling, covering safety flags, variables, portability, error handling, and cross-platform compatibility.

## 1. Safety Flags & Script Header

### POSIX Shell as Default (MANDATORY)

**Unless explicitly specified**, ALL shell scripts in this project MUST be written as **POSIX-compliant shell scripts** (`#!/bin/sh`). Do NOT default to Bash. Rationale:

- Ensures compatibility with minimal environments (Alpine Linux, BusyBox, base Docker images, embedded CI).
- Prevents silent failures when `bash` is not installed.
- Enforces a higher portability standard that benefits all environments.

When Bash-specific features are genuinely required, the script MUST:

1. Use `#!/usr/bin/env bash` (NOT `#!/bin/bash`).
2. Include a comment explaining WHY Bash is required (`# Requires Bash: uses associative arrays`).
3. Explicitly document the Bash version requirement.

> [!WARNING]
> **POSIX `sh` does NOT support `set -o pipefail`**. Using this in a `#!/bin/sh` script will cause it to crash on many Linux systems (e.g. Debian/Ubuntu). Always use standard pipes and check exit codes manually or use Bash if pipefail is critical.

### Global Library (MANDATORY)

To ensure consistency in logging, colors, and argument parsing, ALL functional scripts MUST source the **`scripts/lib/common.sh`** library:

```sh
#!/bin/sh
set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# 1. Execution Context Guard: ensure run from root
guard_project_root

# 2. Argument Parsing (Standardizes --dry-run, -v, -h)
parse_common_args "$@"
```

By sourcing this library, your script automatically gains:

- **`log_info`, `log_success`, `log_warn`, `log_error`**: Standardized colored output.
- **`guard_project_root`**: Safety guard to prevent execution outside the project root.
- **`parse_common_args`**: Unified logic for global flags.

### Bash Header Template (Only When Required)

```bash
#!/usr/bin/env bash
# Description: What this script does
# Requires Bash: <reason>

set -euo pipefail
IFS=$'\n\t'
```

### Shebang Selection

- **`#!/bin/sh`** — **DEFAULT**. Use for all scripts unless Bash features are explicitly required.
- **`#!/usr/bin/env bash`** — Only when Bash-specific features are required (with justification comment).
- **NEVER use `#!/bin/bash`** — Invokes the outdated system Bash 3.x on macOS.

### Embedded Shells & Pre-commit Hooks

- When embedding shell commands inside config files (e.g., `.pre-commit-config.yaml`, `Makefiles`), use `sh -c` not `bash -c`.

### Trap & Cleanup

- Use **`trap`** for cleanup on exit and for signal handling:

  ```bash
  # Create temp file + auto-cleanup
  TMPFILE=$(mktemp)
  trap 'rm -f "$TMPFILE"' EXIT
  trap 'echo "ERROR: Script interrupted" >&2; exit 130' INT TERM

  # Function-based cleanup for complex cleanup logic
  cleanup() {
    local exit_code=$?
    rm -rf "$WORK_DIR"
    if [[ $exit_code -ne 0 ]]; then
      log_error "Script failed with exit code $exit_code"
    fi
  }
  trap cleanup EXIT
  ```

### Execution Mode Guard

- Scripts MUST detect their execution mode at the header:

  ```bash
  # For tool scripts (execute-only) — reject being sourced
  if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "ERROR: This script must be executed, not sourced." >&2
    return 1
  fi

  # For environment scripts (source-only, e.g., load_env.sh) — reject being executed
  if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: This script must be sourced, not executed. Run: . ${BASH_SOURCE[0]}" >&2
    exit 1
  fi
  ```

## 2. Variables & Quoting

### Quoting Rules

- Always **double-quote variable expansions** and command substitutions. Unquoted expansions are subject to word-splitting and pathname expansion:

  ```bash
  # ❌ Unquoted — breaks on spaces, globbing
  cp $source_file $dest_dir
  for file in $(ls $dir); do ...

  # ✅ Quoted — safe with spaces and special characters
  cp "$source_file" "$dest_dir"
  while IFS= read -r file; do ...
  done < <(find "$dir" -type f)
  ```

### Variable Patterns

- Use parameter expansion for safe defaults and required variables:

  ```bash
  # Default value if unset or empty
  LOG_LEVEL="${LOG_LEVEL:-info}"

  # Fail immediately with message if required variable is unset or empty
  : "${DATABASE_URL:?ERROR: DATABASE_URL is required}"
  : "${AWS_REGION:?ERROR: AWS_REGION is required}"

  # Conditional use — expand only if set
  EXTRA_ARGS="${VERBOSE:+--verbose}"
  ```

- Use **`local`** for all variables inside functions to prevent polluting the global scope:

  ```bash
  install_dependency() {
    local package="${1:?Package name required}"
    local version="${2:-latest}"
    local install_path="${INSTALL_DIR}/packages/${package}"
    ...
  }
  ```

- Declare constants with **`readonly`**: `readonly MAX_RETRIES=3 TIMEOUT=30`
- Use **`UPPER_SNAKE_CASE`** for exported/environment variables and `lower_snake_case` for local function variables.

## 3. Functions & Structure

### Script Organization

- Define reusable logic as **named functions**. Keep the main script body minimal — just call functions:

  ```bash
  #!/usr/bin/env bash
  set -euo pipefail

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  readonly SCRIPT_DIR

  # --- Functions ---
  usage() {
    cat <<-EOF
    Usage: $(basename "$0") [OPTIONS] <argument>

    Options:
      -h, --help     Show this help
      -v, --verbose  Enable verbose output
    EOF
    exit "${1:-0}"
  }

  log_info()  { printf '[INFO]  %s\n' "$*" >&1; }
  log_warn()  { printf '[WARN]  %s\n' "$*" >&2; }
  log_error() { printf '[ERROR] %s\n' "$*" >&2; }

  parse_args() {
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -h|--help)    usage ;;
        -v|--verbose) set -x; shift ;;
        --)           shift; break ;;
        -*)           log_error "Unknown option: $1"; usage 1 ;;
        *)            POSITIONAL_ARGS+=("$1"); shift ;;
      esac
    done
  }

  main() {
    parse_args "$@"
    run_install
    verify_installation
  }

  # --- Entry point ---
  main "$@"
  ```

- Use `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` to reliably determine the script's directory regardless of how it was invoked.
- Write a `usage()` function and call it with `exit 1` when invalid arguments are provided.

## 4. Portability & Best Practices

### POSIX vs Bash

- When targeting `/bin/sh` (Alpine containers, minimal CI images), avoid Bash-specific syntax:

  | Bash-only | POSIX sh alternative |
  |-----------|---------------------|
  | `[[ expr ]]` | `[ expr ]` with careful quoting |
  | `${BASH_SOURCE[0]}` | `$0` (less reliable) |
  | `${var,,}` lowercase | `echo "$var" \| tr '[:upper:]' '[:lower:]'` |
  | `${var^^}` uppercase | `echo "$var" \| tr '[:lower:]' '[:upper:]'` |
  | Arrays: `arr=(a b c)` | Space-separated variables or multiple vars |
  | `function foo() {}` | `foo() {}` (no `function` keyword) |
  | `&>>` redirect | `>> file 2>&1` |
  | `source` | `. file` (dot) |
  | `==` in `[ ]` | `=` for string comparison |

### Cross-Platform Patterns

- Test for tool availability with `command -v` — not `which`:

  ```bash
  # ❌ which varies by OS — returns different exit codes, paths, or errors
  which docker

  # ✅ Portable and reliable
  command -v docker &>/dev/null || { log_error "docker is required but not installed"; exit 1; }
  ```

- Avoid GNU-specific flags for cross-platform portability:

  ```bash
  # ❌ GNU grep only
  grep -P '\d+' file.txt      # Perl regex
  sed -i '' 's/old/new/' file # macOS requires '' after -i; Linux doesn't

  # ✅ Portable
  grep -E '[0-9]+' file.txt   # ERE — supported everywhere
  # Use perl for in-place edit portably:
  perl -pi -e 's/old/new/g' file
  ```

- Use **`mktemp`** for temporary files and always clean up in `EXIT` trap:

  ```bash
  TMPFILE=$(mktemp /tmp/myscript.XXXXXX)
  TMPDIR=$(mktemp -d /tmp/myscript-dir.XXXXXX)
  trap 'rm -rf "$TMPFILE" "$TMPDIR"' EXIT
  ```

- Use **`printf`** instead of `echo` for formatted output — `echo` behavior for `-n`, `-e`, and backslashes varies across implementations:

  ```bash
  printf '%s\n' "$message"           # safe, portable
  printf 'File: %s, Size: %d\n' "$f" "$size"  # formatted output
  ```

## 5. Error Handling & Tooling

### Error Patterns

- Print error messages to **stderr** with function context:

  ```bash
  log_error() {
    local func="${FUNCNAME[1]:-main}"
    printf '[ERROR] [%s] %s\n' "$func" "$*" >&2
  }
  ```

- Use meaningful exit codes:
  - `0` — success
  - `1` — general error
  - `2` — misuse of shell command (invalid arguments)
  - `126` — command found but not executable (permission denied)
  - `127` — command not found
  - `128+n` — fatal error signal `n` (e.g., `130` = Ctrl+C, `137` = SIGKILL)

## 6. Cross-Platform Delegation Pattern

For any automation script that must support Windows users, follow the **Single Source of Truth (SSoT) delegation** pattern. All logic lives in `.sh`; wrappers do nothing except forward execution:

```
script.bat   →   script.ps1   →   script.sh
(CMD entry)      (PS entry)       (POSIX logic, SSoT)
```

### Template: `script.sh` (Primary Logic)

```sh
#!/bin/sh
# Description: Your script description
set -eu
# ... all logic here ...
```

### Template: `script.ps1` (PowerShell Wrapper)

```powershell
# PowerShell wrapper — delegates to script.sh
. "$PSScriptRoot/lib/common.ps1"
Invoke-ShellDelegation "script.sh" ($args -join " ")
```

### Template: `script.bat` (CMD Wrapper)

```bat
@echo off
REM CMD wrapper — delegates to script.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0script.ps1" %*
```

> **Rule**: Wrappers MUST NOT contain any logic. Copy-pasting the `.sh` logic into `.ps1` is a violation of this rule.

## 7. Linting Requirements (All Script Types)

ALL scripts MUST pass their respective linters before being committed. This is enforced by pre-commit hooks and CI.

| Script Type | Linter | Required Flags |
|-------------|--------|----------------|
| `.sh` (POSIX) | `shellcheck` | `--shell=sh` |
| `.sh` (Bash) | `shellcheck` | `--shell=bash` |
| `.ps1` | `PSScriptAnalyzer` | `Invoke-ScriptAnalyzer -Path .` |
| `.bat` | manual review | Keep minimal — delegate only |

> **PowerShell Linting Note (`PSAvoidUsingWriteHost`)**:
> Never use `Write-Host` for output in `.ps1` scripts, as it cannot be suppressed, captured, or redirected in older PS versions and breaks CI pipelines. Always use `Write-Output` (or `Write-Warning`/`Write-Error` where semantically appropriate) instead.

```bash
# CI step — lint all shell scripts
find . -name "*.sh" -not -path "*/node_modules/*" \
  -exec shellcheck --shell=sh --severity=warning {} +

# CI step — lint all PowerShell scripts (on Windows runner)
Get-ChildItem -Recurse -Filter "*.ps1" | ForEach-Object {
    Invoke-ScriptAnalyzer -Path $_.FullName -Severity Warning
}
```

Document any necessary `# shellcheck disable=SC2034` exclusions with a reason. Suppressing linter warnings without justification is not permitted.

## 8. High-Performance & Robustness Patterns

### Atomic File Updates (Build-then-Swap)

When a script needs to modify a file, avoid direct append/redirection to the source. Use a temporary file to ensure atomicity.

```sh
# POSIX-compliant atomic update
tmp_file=$(mktemp)
# 1. Process/Build
cat header.txt > "$tmp_file"
sed 's/foo/bar/g' source.txt >> "$tmp_file"
# 2. Atomic Swap
mv "$tmp_file" source.txt
```

### Universal Versioning Detection

Standardize version detection across different ecosystems to ensure a zero-config experience.

```sh
# Helper to extract version from various manifests
get_project_version() {
  if [ -f "package.json" ]; then
    grep '"version":' package.json | head -n 1 | sed 's/.*"version":[[:space:]]*"//;s/".*//'
  elif [ -f "Cargo.toml" ]; then
    grep '^version =' Cargo.toml | head -n 1 | sed -e 's/.*"\(.*\)"/\1/' -e "s/.*'\(.*\)'/\1/"
  elif [ -f "VERSION" ]; then
    cat VERSION | head -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
  fi
}
```

### Execution Context Guard

Prevent scripts from running in unintentional directories.

```sh
# Verify project root
if [ ! -f "CHANGELOG.md" ] || [ ! -d ".git" ]; then
  printf "ERROR: This script must be run from the project root.\n" >&2
  exit 1
fi
```
