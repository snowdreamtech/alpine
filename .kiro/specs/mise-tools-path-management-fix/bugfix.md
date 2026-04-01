# Bugfix Requirements Document

## Introduction

This document addresses a systemic architectural defect in the mise tool PATH management system that affects all 20+ tools installed via mise. The root cause has been identified through comprehensive analysis (see `.kiro/specs/ci-gitleaks-not-found-fix/root-cause-analysis.md`): the `refresh_mise_cache()` function is completely disabled, and there is no unified PATH management mechanism after tool installation. This causes `resolve_bin` to fail in finding newly installed tools, particularly in CI environments where mise shims directories may not be in the PATH.

The current state includes a temporary workaround in `install_gitleaks()` that manually adds mise shims to PATH, but this approach does not scale to the 20+ other affected tools. This bugfix implements a comprehensive solution (Hybrid Approach - Solution 3) that addresses the root cause systemically.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN `run_mise install <tool>` completes successfully THEN the system does not automatically ensure mise shims directory is in PATH

1.2 WHEN `refresh_mise_cache()` is called THEN the system returns empty JSON `{}` instead of actual mise tool metadata

1.3 WHEN a tool is installed via mise in a CI environment THEN the system does not persist the mise shims PATH to GITHUB_PATH

1.4 WHEN `resolve_bin` attempts to find a newly installed mise tool THEN the system may fail because mise shims directory is not in the current session's PATH

1.5 WHEN multiple tools are installed via mise THEN each tool installation requires individual PATH management workarounds (as seen in Gitleaks fix)

1.6 WHEN `mise ls --json` is executed THEN the system may hang indefinitely due to proxy/network issues without timeout protection

### Expected Behavior (Correct)

2.1 WHEN `run_mise install <tool>` completes successfully THEN the system SHALL automatically add mise shims directory to PATH if not already present

2.2 WHEN `refresh_mise_cache()` is called THEN the system SHALL execute `mise ls --json` with timeout protection (5 seconds) and return valid tool metadata or empty JSON on timeout

2.3 WHEN a tool is installed via mise in a CI environment (GITHUB_PATH is set) THEN the system SHALL automatically persist mise shims directory to GITHUB_PATH

2.4 WHEN `resolve_bin` attempts to find a newly installed mise tool THEN the system SHALL successfully locate the tool via mise shims in PATH

2.5 WHEN multiple tools are installed via mise THEN the system SHALL apply unified PATH management automatically without requiring per-tool workarounds

2.6 WHEN `mise ls --json` is executed with timeout protection THEN the system SHALL return within 5 seconds or gracefully fall back to empty JSON

2.7 WHEN the Gitleaks temporary PATH management fix exists THEN the system SHALL remove it as the root fix makes it redundant

### Unchanged Behavior (Regression Prevention)

3.1 WHEN mise is not installed THEN the system SHALL CONTINUE TO handle the absence gracefully without errors

3.2 WHEN tools are already in PATH from other sources THEN the system SHALL CONTINUE TO find and use them correctly

3.3 WHEN `run_mise` is called with non-install commands (e.g., `run_mise list`) THEN the system SHALL CONTINUE TO execute without PATH modifications

3.4 WHEN `MISE_LOCKED` environment variable is set THEN the system SHALL CONTINUE TOrespect the lock mode for appropriate tool installations

3.5 WHEN tools are installed in local development environments THEN the system SHALL CONTINUE TO work correctly with existing shell configurations

3.6 WHEN `resolve_bin` uses fallback resolution methods (direct PATH lookup, `mise which`, filesystem search) THEN the system SHALL CONTINUE TO function correctly

3.7 WHEN `get_version` checks tool versions THEN the system SHALL CONTINUE TO return accurate version information

3.8 WHEN network issues prevent `mise ls --json` from completing THEN the system SHALL CONTINUE TO function using direct command resolution (existing fallback behavior)
