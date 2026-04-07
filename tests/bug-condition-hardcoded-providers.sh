#!/usr/bin/env bash
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# Bug Condition Exploration Test for Scripts Version Centralization
# **Validates: Requirements 1.1-1.36**
#
# CRITICAL: This test MUST FAIL on unfixed code - failure confirms the bug exists
# DO NOT attempt to fix the test or the code when it fails
# NOTE: This test encodes the expected behavior - it will validate the fix when it passes after implementation
#
# GOAL: Surface counterexamples that demonstrate hardcoded provider values exist across the codebase
# SCOPED PBT APPROACH: Search for all instances of `local _PROVIDER="[^$]+"` pattern in `scripts/lib/langs/*.sh` files
#
# Expected counterexamples on UNFIXED code:
#   - GitHub providers: ~20 instances (e.g., `local _PROVIDER="github:hadolint/hadolint"`)
#   - NPM providers: ~10 instances (e.g., `local _PROVIDER="npm:prettier"`)
#   - Pipx providers: ~5 instances (e.g., `local _PROVIDER="pipx:sqlfluff"`)
#   - Gem providers: ~1 instance (e.g., `local _PROVIDER="gem:rubocop"`)
#
# EXPECTED OUTCOME: Test FAILS with hardcoded instances found (this is correct - it proves the bug exists)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
SCRIPTS_DIR="scripts/lib/langs"

echo "=========================================="
echo "Bug Condition Exploration Test"
echo "Property 1: Bug Condition - Hardcoded Provider Detection"
echo "=========================================="
echo ""

# Check if scripts directory exists
if [[ ! -d ${SCRIPTS_DIR} ]]; then
  echo -e "${RED}ERROR: Directory ${SCRIPTS_DIR} not found${NC}"
  exit 1
fi

echo "Searching for hardcoded _PROVIDER assignments in ${SCRIPTS_DIR}/*.sh"
echo ""

# Search for hardcoded _PROVIDER assignments
# Pattern: local _PROVIDER="<anything that doesn't start with $>"
# This matches hardcoded strings but not variable references like ${VER_*_PROVIDER:-}
HARDCODED_PROVIDERS=$(grep -rn 'local _PROVIDER="[^$]' "${SCRIPTS_DIR}"/*.sh 2>/dev/null || true)

# Count instances
INSTANCE_COUNT=$(echo "${HARDCODED_PROVIDERS}" | grep -c 'local _PROVIDER=' || true)

echo "=========================================="
echo "RESULTS"
echo "=========================================="
echo ""
echo "Total hardcoded _PROVIDER instances found: ${INSTANCE_COUNT}"
echo ""

if [[ ${INSTANCE_COUNT} -eq 0 ]]; then
  echo -e "${GREEN}✓ PASS: No hardcoded provider values found${NC}"
  echo ""
  echo "This means the bug has been FIXED - all scripts now use centralized variables."
  exit 0
fi

# Document all counterexamples
echo "=========================================="
echo "COUNTEREXAMPLES (Hardcoded Provider Instances)"
echo "=========================================="
echo ""

# Group by provider type
echo "--- GitHub Providers ---"
GITHUB_COUNT=$(echo "${HARDCODED_PROVIDERS}" | grep -c 'github:' || true)
echo "Count: ${GITHUB_COUNT}"
echo "${HARDCODED_PROVIDERS}" | grep 'github:' || echo "None found"
echo ""

echo "--- NPM Providers ---"
NPM_COUNT=$(echo "${HARDCODED_PROVIDERS}" | grep -c 'npm:' || true)
echo "Count: ${NPM_COUNT}"
echo "${HARDCODED_PROVIDERS}" | grep 'npm:' || echo "None found"
echo ""

echo "--- Pipx Providers ---"
PIPX_COUNT=$(echo "${HARDCODED_PROVIDERS}" | grep -c 'pipx:' || true)
echo "Count: ${PIPX_COUNT}"
echo "${HARDCODED_PROVIDERS}" | grep 'pipx:' || echo "None found"
echo ""

echo "--- Gem Providers ---"
GEM_COUNT=$(echo "${HARDCODED_PROVIDERS}" | grep -c 'gem:' || true)
echo "Count: ${GEM_COUNT}"
echo "${HARDCODED_PROVIDERS}" | grep 'gem:' || echo "None found"
echo ""

echo "--- Other Providers (Runtime/Simple) ---"
OTHER_COUNT=$(echo "${HARDCODED_PROVIDERS}" | grep -v 'github:' | grep -v 'npm:' | grep -v 'pipx:' | grep -v 'gem:' | grep -c 'local _PROVIDER=' || true)
echo "Count: ${OTHER_COUNT}"
echo "${HARDCODED_PROVIDERS}" | grep -v 'github:' | grep -v 'npm:' | grep -v 'pipx:' | grep -v 'gem:' || echo "None found"
echo ""

# Detailed breakdown by file
echo "=========================================="
echo "BREAKDOWN BY FILE"
echo "=========================================="
echo ""

for file in "${SCRIPTS_DIR}"/*.sh; do
  if [[ -f ${file} ]]; then
    filename=$(basename "${file}")
    file_matches=$(grep -n 'local _PROVIDER="[^$]' "${file}" 2>/dev/null || true)
    if [[ -n ${file_matches} ]]; then
      count=$(echo "${file_matches}" | wc -l | tr -d ' ')
      echo "${filename}: ${count} instance(s)"
      printf '  %s\n' "${file_matches}"
      echo ""
    fi
  fi
done

echo "=========================================="
echo "ANALYSIS"
echo "=========================================="
echo ""
echo "Documented in bugfix.md: 36 instances (requirements 1.1-1.36)"
echo "Actually found: ${INSTANCE_COUNT} instances"
echo ""

# Calculate the breakdown
DOCUMENTED_TOOLS=36
RUNTIME_PROVIDERS=${OTHER_COUNT}
TOOL_PROVIDERS=$((GITHUB_COUNT + NPM_COUNT + PIPX_COUNT + GEM_COUNT))

echo "Breakdown:"
echo "  - Tool providers (github/npm/pipx/gem): ${TOOL_PROVIDERS}"
echo "  - Runtime providers (node/python/go/rust/etc): ${RUNTIME_PROVIDERS}"
echo ""

if [[ ${TOOL_PROVIDERS} -eq ${DOCUMENTED_TOOLS} ]]; then
  echo "The ${TOOL_PROVIDERS} tool provider instances match the 36 documented in bugfix.md."
  echo "The ${RUNTIME_PROVIDERS} additional instances are runtime providers (node, python, go, rust, etc)."
  echo "These are mentioned in requirement 1.36 but not individually enumerated."
elif [[ ${TOOL_PROVIDERS} -lt ${DOCUMENTED_TOOLS} ]]; then
  echo "Found fewer tool providers (${TOOL_PROVIDERS}) than documented (${DOCUMENTED_TOOLS})."
  echo "This could indicate a partial fix hasbeen applied."
else
  echo "Found more tool providers (${TOOL_PROVIDERS}) than documented (${DOCUMENTED_TOOLS})."
  echo "This could indicate new hardcoded values were added or documentation is out of sync."
fi

echo ""
echo "=========================================="
echo "TEST VERDICT"
echo "=========================================="
echo ""

echo -e "${YELLOW}✗ EXPECTED FAILURE: Found ${INSTANCE_COUNT} hardcoded instances${NC}"
echo ""
echo "This is the CORRECT outcome for unfixed code - the test successfully detected the bug."
echo "These counterexamples prove that hardcoded provider values exist across the codebase."
echo ""
echo "Counterexample summary:"
echo "  - GitHub providers: ${GITHUB_COUNT}"
echo "  - NPM providers: ${NPM_COUNT}"
echo "  - Pipx providers: ${PIPX_COUNT}"
echo "  - Gem providers: ${GEM_COUNT}"
echo "  - Runtime/Other providers: ${RUNTIME_PROVIDERS}"
echo "  - TOTAL: ${INSTANCE_COUNT}"
echo ""
echo "Next steps:"
echo "  1. These counterexamples document the scope of the bug"
echo "  2. Implement the fix to replace hardcoded values with centralized variables"
echo "  3. Re-run this test - it should PASS (0 instances) after the fix is applied"
echo ""

# Exit with failure code since we found hardcoded instances (bug exists)
exit 1
