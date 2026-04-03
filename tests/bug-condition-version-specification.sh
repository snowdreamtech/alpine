#!/usr/bin/env bash
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# Bug Condition Exploration Test for Mise Version Specification
# **Validates: Requirements 1.1, 1.2, 1.3, 1.4**
#
# CRITICAL: This test MUST FAIL on unfixed code - failure confirms the bug exists
# DO NOT attempt to fix the test or the code when it fails
# NOTE: This test encodes the expected behavior - it will validate the fix when it passes after implementation
#
# GOAL: Surface counterexamples that demonstrate mise installs latest versions instead of pinned versions
# SCOPED PBT APPROACH: Scope the property to concrete failing cases (hadolint, shellcheck, actionlint, shfmt, dockerfile-utils)
#
# Expected counterexamples on UNFIXED code:
#   - run_mise insta-} suffix
#   - Commands do NOT contain version specifications
#   - Mise will install latest versions instead of versions.sh pinned versions
#
# EXPECTED OUTCOME: Test FAILS with missing version suffixes found (this is correct - it proves the bug exists)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
SCRIPTS_DIR="scripts/lib/langs"
VERSIONS_FILE="scripts/lib/versions.sh"

echo "=========================================="
echo "Bug Condition Exploration Test"
echo "Property 1: Bug Condition - Version Locking Violation Detection"
echo "=========================================="
echo ""

# Check if scripts directory exists
if [[ ! -d ${SCRIPTS_DIR} ]]; then
  echo -e "${RED}ERROR: Directory ${SCRIPTS_DIR} not found${NC}"
  exit 1
fi

# Check if versions.sh exists
if [[ ! -f ${VERSIONS_FILE} ]]; then
  echo -e "${RED}ERROR: File ${VERSIONS_FILE} not found${NC}"
  exit 1
fi

echo "Searching for run_mise install calls without version suffixes in ${SCRIPTS_DIR}/*.sh"
echo ""

# Search for run_mise install calls with _PROVIDER but without version suffix
# Pattern: run_mise install "${_PROVIDER:-}" (without @${_VERSION or @${)
# This matches calls that are missing version specifications

BUGGY_CALLS=$(grep -rn 'run_mise install[[:space:]]*"\${_PROVIDER:-}"' "${SCRIPTS_DIR}"/*.sh 2>/dev/null |
  grep -v '@\${_VERSION' |
  grep -v '@\${' || true)

# Count instances
INSTANCE_COUNT=$(echo "${BUGGY_CALLS}" | grep -c 'run_mise install' || true)

echo "=========================================="
echo "RESULTS"
echo "=========================================="
echo ""
echo "Total run_mise install calls without version suffix: ${INSTANCE_COUNT}"
echo ""

if [[ ${INSTANCE_COUNT} -eq 0 ]]; then
  echo -e "${GREEN}✓ PASS: All run_mise install calls include version suffixes${NC}"
  echo ""
  echo "This means the bug has been FIXED - all mise install calls now enforce version locking."
  exit 0
fi

# Document all counterexamples
echo "=========================================="
echo "COUNTEREXAMPLES (Missing Version Suffixes)"
echo "=========================================="
echo ""

# Focus on the concrete failing cases mentioned in the task
FOCUS_TOOLS="hadolint shellcheck actionlint shfmt dockerfile-utils"

echo "--- Focused Analysis: Known Failing Tools ---"
echo ""

for tool in ${FOCUS_TOOLS}; do
  tool_matches=$(echo "${BUGGY_CALLS}" | grep -i "${tool}" || true)
  if [[ -n ${tool_matches} ]]; then
    echo -e "${BLUE}${tool}:${NC}"
    echo "${tool_matches}" | sed 's/^/  /'

    # Extract the version from versions.sh for this tool
    tool_upper=$(echo "${tool}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    version_var="VER_${tool_upper}"
    pinned_version=$(grep "^${version_var}=" "${VERSIONS_FILE}" 2>/dev/null | cut -d'"' -f2 || echo "NOT_FOUND")

    if [[ ${pinned_version} != "NOT_FOUND" ]]; then
      echo -e "  ${YELLOW}Pinned version in versions.sh: ${pinned_version}${NC}"
      echo -e "  ${RED}Bug: Will install LATEST instead of ${pinned_version}${NC}"
    fi
    echo ""
  fi
done

echo "--- All Affected Files ---"
echo ""

# Detailed breakdown by file
for file in "${SCRIPTS_DIR}"/*.sh; do
  if [[ -f ${file} ]]; then
    filename=$(basename "${file}")
    file_matches=$(grep -n'run_mise install.*"\${_PROVIDER:-}"' "${file}" 2>/dev/null |
      grep -v '@\${_VERSION' |
      grep -v '@\${' || true)
    if [[ -n ${file_matches} ]]; then
      count=$(echo "${file_matches}" | wc -l | tr -d ' ')
      echo "${filename}: ${count} instance(s)"
      echo "${file_matches}" | sed 's/^/  /'
      echo ""
    fi
  fi
done

echo "=========================================="
echo "ANALYSIS"
echo "=========================================="
echo ""

# Analyze the bug pattern
echo "Bug Pattern Analysis:"
echo '  - Buggy pattern: run_mise install "\${_PROVIDER:-}"'
echo '  - Expected pattern: run_mise install "\${_PROVIDER:-}@\${_VERSION:-}"'
echo ""

# Check if _VERSION variables are defined
echo "Checking if _VERSION variables are defined in affected functions..."
echo ""

missing_version_vars=0
for tool in ${FOCUS_TOOLS}; do
  tool_upper=$(echo "${tool}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  version_var="VER_${tool_upper}"

  # Check if version exists in versions.sh
  if grep -q "^${version_var}=" "${VERSIONS_FILE}" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} ${version_var} exists in versions.sh"
  else
    echo -e "  ${RED}✗${NC} ${version_var} NOT FOUND in versions.sh"
    ((missing_version_vars++))
  fi
done

echo ""

if [[ ${missing_version_vars} -eq 0 ]]; then
  echo "All version variables exist in versions.sh."
  echo "Root cause: Functions are NOT using these variables in run_mise install calls."
else
  echo "Some version variables are missing from versions.sh."
  echo "Root cause: Both missing variables AND missing usage in run_mise install calls."
fi

echo ""
echo "=========================================="
echo "ROOT CAUSE HYPOTHESIS"
echo "=========================================="
echo ""

echo "Based on the counterexamples found, the root causes are:"
echo ""
echo "1. Inconsistent Version Specification Pattern:"
echo '   - Some functions use: run_mise install "\${_PROVIDER:-}@\${_VERSION:-}" (correct)'
echo '   - Affected functions use: run_mise install "\${_PROVIDER:-}" (buggy)'
echo ""
echo "2. Missing Version Variable Assignment:"
echo "   - Functions define _PROVIDER but fail to define _VERSION from versions.sh"
echo '   - Example: local _VERSION="\${VER_HADOLINT:-}" is missing'
echo ""
echo "3. Copy-Paste Error Propagation:"
echo "   - The buggy pattern was likely copied across multiple language modules"
echo ""

echo "=========================================="
echo "EXPECTED BEHAVIOR"
echo "=========================================="
echo ""

echo "After the fix is applied, ALL run_mise install calls should:"
echo '  1. Include @\${_VERSION:-} suffix to enforce version locking'
echo "  2. Install exact versions from versions.sh"
echo "  3. Ensure reproducibility across multiple runs and environments"
echo ""

echo "Example fix for hadolint:"
echo '  Before: run_mise install "\${_PROVIDER:-}"'
echo '  After:  run_mise install "\${_PROVIDER:-}@\${_VERSION:-}"'
echo ""

echo "=========================================="
echo "TEST VERDICT"
echo "=========================================="
echo ""

echo -e "${YELLOW}✗ EXPECTED FAILURE: Found ${INSTANCE_COUNT} calls without version suffix${NC}"
echo ""
echo "This is the CORRECT outcome for unfixed code - the test successfully detected the bug."
echo "These counterexamples prove that mise will install latest versions instead of pinned versions."
echo ""

# Provide detailed counterexample summary for focused tools
echo "Counterexample summary (focused tools):"
for tool in ${FOCUS_TOOLS}; do
  tool_count=$(echo "${BUGGY_CALLS}" | grep -ic "${tool}" || true)
  if [[ ${tool_count} -gt 0 ]]; then
    tool_upper=$(echo "${tool}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    version_var="VER_${tool_upper}"
    pinned_version=$(grep "^${version_var}=" "${VERSIONS_FILE}" 2>/dev/null | cut -d'"' -f2 || echo "?")
    echo "  - ${tool}: ${tool_count} instance(s) - will install LATEST instead of ${pinned_version}"
  fi
done

echo ""
echo "Total affected calls: ${INSTANCE_COUNT}"
echo ""
echo "Next steps:"
echo "  1. These counterexamples document the scope of the bug"
echo '  2. Implement the fix to add @${_VERSION:-} suffix to all affected calls'
echo "  3. Re-run this test - it should PASS (0 instances) after the fix is applied"
echo ""

# Exit with failure code since we found buggy calls (bug exists)
exit 1
