# CI Linting Tools Troubleshooting Guide

## Problem Summary

Tools (shfmt, editorconfig-checker) fail in CI with:
```
Successfully installed github:mvdan/sh
❌ shfmt not found in CI. Failing.
```

## Root Causes Identified

### 1. mise State Caching
- After `mise install`, the tool may not be immediately available
- mise's internal state needs to be refreshed with `mise reshim`

### 2. Hollow Shims (Windows)
- mise creates shim files but actual binaries may not download
- `mise which` fails even though shim exists

### 3. Binary Name Mismatches
- editorconfig-checker's binary is `ec`, not `editorconfig-checker`
- Tool spec uses `github:editorconfig-checker/editorconfig-checker`

### 4. Multiple Caching Layers
- `get_version()` checks mise registry, not executability
- `install_*()` functions skip if version matches
- `run_mise()` also has skip optimization

## Complete Solution

### Layer 1: Setup Phase (install_* functions)

**Location**: `scripts/lib/langs/shell.sh`, `scripts/lib/langs/base.sh`

**Logic**:
1. Check if tool version matches required version
2. In CI, verify tool is actually executable:
   - Try `command -v <binary>`
   - Try `mise exec <tool-spec> -- <binary> --version`
3. If not executable, force uninstall and reinstall
4. After installation, verify again with reshim

**Key Code**:
```bash
if is_ci_env; then
  if command -v shfmt >/dev/null 2>&1; then
    return 0  # Tool is executable
  elif mise exec "${_PROVIDER:-}" -- shfmt --version >/dev/null 2>&1; then
    return 0  # Tool works via mise exec
  else
    # Force reinstall
    mise uninstall "${_PROVIDER:-}" 2>/dev/null || true
  fi
fi

# After installation
mise reshim 2>/dev/null || true
sleep 1
```

### Layer 2: run_mise Optimization

**Location**: `scripts/lib/common.sh`

**Change**: Disable version-match skip in CI
```bash
if [ "${_C_VER:-}" != "-" ] && [ -n "${_R_VER:-}" ]; then
  case "${_R_VER:-}" in "${_C_VER:-}"*)
    if ! is_ci_env; then  # Only skip in local dev
      _SKIP_INSTALL=1
    fi
    ;;
  esac
fi
```

### Layer 3: Lint Wrapper Fallback

**Location**: `scripts/lib/lint-wrapper.sh`

**6-Step Recovery Process**:

1. **Try mise exec** - Standard execution path
2. **Check mise registry** - Verify tool is registered
3. **Uninstall + Install** - Force clean installation
4. **Reshim + Wait** - Refresh mise state
5. **Retry mise exec** - Try again after refresh
6. **Direct execution** - Find install path and execute directly

**Key Code**:
```bash
# Step 1: Try mise exec
if mise exec "${_EXEC_TARGET:-}" -- "${_LINTER_BIN:-}" --version >/dev/null 2>&1; then
  exec mise exec "${_EXEC_TARGET:-}" -- "${_LINTER_BIN:-}" "$@"
fi

# Step 3: Install
mise install "${_EXEC_TARGET:-}"

# Step 4: Refresh
mise reshim 2>/dev/null || true
sleep 1

# Step 6: Direct execution
_INSTALL_PATH=$(mise where "${_EXEC_TARGET:-}" 2>/dev/null || true)
for _BIN_DIR in "bin" "."; do
  if [ -x "${_INSTALL_PATH:-}/${_BIN_DIR}/${_LINTER_BIN:-}" ]; then
    exec "${_INSTALL_PATH:-}/${_BIN_DIR}/${_LINTER_BIN:-}" "$@"
  fi
done
```

## Tool-Specific Configurations

### shfmt
- **Tool Spec**: `github:mvdan/sh`
- **Binary Name**: `shfmt`
- **mise.toml**: `"github:mvdan/sh" = { version = "3.13.1", bin = "shfmt" }`

### editorconfig-checker
- **Tool Spec**: `github:editorconfig-checker/editorconfig-checker`
- **Binary Name**: `ec` (NOT editorconfig-checker!)
- **mise.toml**: `"github:editorconfig-checker/editorconfig-checker" = { version = "3.6.1", bin = "ec-*" }`

## Debugging

### Enable Debug Logging

Set in CI workflow:
```yaml
env:
  VERBOSE: 2
```

### Check Tool Installation

```bash
# List installed tools
mise list

# Check tool location
mise where github:mvdan/sh

# Test execution
mise exec github:mvdan/sh -- shfmt --version

# Check shims
ls -la ~/.local/share/mise/shims/
```

### Common Issues

1. **"Successfully installed but not found"**
   - Solution: Added reshim + sleep + direct execution fallback

2. **"Binary name mismatch"**
   - Solution: Use correct binary name (ec for editorconfig-checker)

3. **"Hollow shims on Windows"**
   - Solution: Multiple verification methods + direct execution

4. **"Version matches but not executable"**
   - Solution: CI-specific executability verification

## Testing

To test locally:
```bash
# Simulate CI environment
export CI=true

# Run setup
make setup

# Run linting
make lint
```

## Commit History

- `c56679c`: Fix editorconfig-checker binary name to 'ec'
- `5404189`: Verify tool executability in CI
- `dee60a7`: Force reinstall non-executable tools
- `40ab04d`: Add aggressive reinstall logic in lint-wrapper
- `21be93b`: Add reshim and direct execution fallback
- `bac4a9c`: Comprehensive tool installation and execution fix

## Success Criteria

✅ Tools install successfully in setup phase
✅ Tools are executable after installation
✅ Linting hooks can find and execute tools
✅ Works on all platforms (Linux, macOS, Windows)
✅ Detailed logging for debugging
✅ Multiple fallback mechanisms
