# Implementation Plan

- [x] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - Gitleaks Not Found After Installation
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists
  - **Scoped PBT Approach**: Scope the property to CI environment where mise cache is disabled and mise shims are not in PATH
  - Test that after `run_mise install gitleaks`, `resolve_bin "gitleaks"` returns a valid path
  - Simulate CI conditions: empty mise cache (`_G_MISE_LS_JSON_CACHE="{}"`), mise shims not in PATH
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found: `resolve_bin "gitleaks"` returns empty/null despite successful installation
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Other Tool Detection Unchanged
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for non-Gitleaks tools (Node.js, Python, Ruby, Shellcheck, Checkmake, etc.)
  - Write property-based tests capturing observed behavior patterns:
    - Node.js detection via `resolve_bin "node"` continues to work
    - Python detection via `resolve_bin "python3"` continues to work
    - Shellcheck detection via `resolve_bin "shellcheck"` continues to work
    - Checkmake detection via `resolve_bin "checkmake"` continues to work
  - Property-based testing generates many test cases for stronger guarantees
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 3. Fix for Gitleaks detection in CI environment
  - [x] 3.1 Implement the fix in install_gitleaks()
    - Add explicit PATH management after successful `run_mise install gitleaks`
    - Check if `${_G_MISE_SHIMS_BASE}` is already in PATH using case statement
    - If not present, prepend mise shims directory to PATH: `export PATH="${_G_MISE_SHIMS_BASE}:$PATH"`
    - Call `refresh_mise_cache` after installation to update metadata (for future compatibility)
    - Add verification step: check that `mise which gitleaks` returns valid path after installation
    - _Bug_Condition: isBugCondition(input) where input.tool == "gitleaks" AND input.installedViaMise == true AND input.miseCache == "{}" AND input.miseShimsNotInPath == true_
    - _Expected_Behavior: resolve_bin("gitleaks") returns valid path after installation via mise shims, PATH, or mise which_
    - _Preservation: Other tool detection (Node.js, Python, Ruby, Shellcheck, etc.) remains unchanged_
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4_

  - [x] 3.2 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Gitleaks Found After Installation
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1
    - **EXPECTED OUTCOME**: Test PASSES (confirms bug is fixed)
    - Verify that `resolve_bin "gitleaks"` now returns valid path in CI-like conditions
    - _Requirements: 2.1, 2.2, 2.4_

  - [x] 3.3 Verify preservation tests still pass
    - **Property 2: Preservation** - Other Tool Detection Unchanged
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm all tests still pass after fix (no regressions in Node.js, Python, Ruby, Shellcheck, Checkmake detection)
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 4. Checkpoint - Ensure all tests pass
  - Run full test suite to verify bug is fixed and no regressions introduced
  - Verify `make setup && make check-env` works correctly in CI-like environment
  - Ensure all property-based tests pass (both bug condition and preservation)
  - Ask the user if questions arise
