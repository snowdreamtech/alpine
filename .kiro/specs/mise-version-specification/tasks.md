# Implementation Plan

- [x] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - Version Locking Violation Detection
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate mise installs latest versions instead of pinned versions
  - **Scoped PBT Approach**: Scope the property to concrete failing cases (hadolint, shellcheck, actionlint, shfmt, dockerfile-utils) to ensure reproducibility
  - Test that `run_mise install "${_PROVIDER:-}"` without version suffix causes mise to install latest version instead of versions.sh pinned version
  - Create test script that mocks/captures mise install commands for affected tools (hadolint, shellcheck, actionlint, shfmt, dockerfile-utils)
  - Verify commands do NOT contain `@${_VERSION:-}` suffix
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found (e.g., "hadolint installs latest 2.15.0 instead of pinned 2.14.0")
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. Write preservation property tests (BEFORE implementing fix)
  - **Proper
IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for non-buggy installation patterns
  - Test fast-path version checks: verify `is_version_match` skips reinstallation when correct version exists
  - Test DRY_RUN mode: verify installations are previewed without execution
  - Test runtime-only installs: verify `run_mise install ruby` works without version suffix
  - Test version extraction pattern: verify `run_mise install "perl@$(get_mise_tool_version perl)"` works correctly
  - Test error handling: verify installation failures are logged with `|| _STAT="❌ Failed"`
  - Test tools already in .mise.toml: verify they respect .mise.toml as source of truth
  - Write property-based tests capturing observed behavior patterns
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 3. Fix for mise version specification bug

  - [x] 3.1 Fix scripts/lib/langs/base.sh
    - Add `local _VERSION="${VER_GITLEAKS:-}"` to `install_gitleaks()`
    - Transform `run_mise install gitleaks` to `run_mise install "gitleaks@${_VERSION:-}"`
    - Add `local _VERSION="${VER_CHECKMAKE:-}"` to `install_checkmake()`
    - Transform `run_mise install checkmake` to `run_mise install "checkmake@${_VERSION:-}"`
    - Add `local _VERSION="${VER_EDITORCONFIG_CHECKER:-}"` to `install_editorconfig_checker()`
    - Transform `run_mise install "${_PROVIDER:-}"` to `run_mise install "${_PROVIDER:-}@${_VERSION:-}"`
    - Add `local _VERSION="${VER_GORELEASER:-}"` to `install_goreleaser()`
    - Transform `run_mise install "${_PROVIDER:-}"` to `run_mise install "${_PROVIDER:-}@${_VERSION:-}"`
    - _Bug_Condition: isBugCondition(installCall) where installCall matches 'run_mise install "${_PROVIDER:-}"' without version suffix_
    - _Expected_Behavior: All install calls SHALL include @${_VERSION:-} suffix to enforce version locking from versions.sh_
    - _Preservation: Fast-path checks, DRY_RUN mode, error handling, and log formatting remain unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.4, 3.5_

  - [x] 3.2 Fix scripts/lib/langs/shell.sh
    - Add `local _VERSION="${VER_SHFMT:-}"` to `install_shfmt()`
    - Transform `run_mise install "${_PROVIDER:-}"` to `run_mise install "${_PROVIDER:-}@${_VERSION:-}"`
    - Add `local _VERSION="${VER_SHELLCHECK:-}"` to `install_shellcheck()`
    - Transform `run_mise install "${_PROVIDER:-}"` to `run_mise install "${_PROVIDER:-}@${_VERSION:-}"`
    - Add `local _VERSION="${VER_ACTIONLINT:-}"` to `install_actionlint()`
    - Transform `run_mise install "${_PROVIDER:-}"` to `run_mise install "${_PROVIDER:-}@${_VERSION:-}"`
    - _Bug_Condition: isBugCondition(installCall) where installCall matches 'run_mise install "${_PROVIDER:-}"' without version suffix_
    - _Expected_Behavior: All install calls SHALL include @${_VERSION:-} suffix to enforce version locking from versions.sh_
    - _Preservation: Fast-path checks, DRY_RUN mode, error handling, and log formatting remain unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.4, 3.5_

  - [x] 3.3 Fix scripts/lib/langs/docker.sh
    - Add `local _VERSION="${VER_HADOLINT:-}"` to `install_hadolint()`
    - Transform `run_mise install "${_PROVIDER:-}"` to `run_mise install "${_PROVIDER:-}@${_VERSION:-}"`
    - Add `local _VERSION="${VER_DOCKERFILE_UTILS:-}"` to `install_dockerfile_utils()`
    - Transform `run_mise install "${_PROVIDER:-}"` to `run_mise install "${_PROVIDER:-}@${_VERSION:-}"`
    - _Bug_Condition: isBugCondition(installCall) where installCall matches 'run_mise install "${_PROVIDER:-}"' without version suffix_
    - _Expected_Behavior: All install calls SHALL include @${_VERSION:-} suffix to enforce version locking from versions.sh_
    - _Preservation: Fast-path checks, DRY_RUN mode, error handling, and log formatting remain unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.4, 3.5_

  - [x] 3.4 Fix scripts/lib/langs/java.sh
    - Add `local _VERSION="${VER_JAVA_FORMAT:-}"` to `install_java_lint()`
    - Transform `run_mise install "${_PROVIDER:-}"` to `run_mise install "${_PROVIDER:-}@${_VERSION:-}"`
    - _Bug_Condition: isBugCondition(installCall) where installCall matches 'run_mise install "${_PROVIDER:-}"' without version suffix_
    - _Expected_Behavior: All install calls SHALL include @${_VERSION:-} suffix to enforce version locking from versions.sh_
    - _Preservation: Fast-path checks, DRY_RUN mode, error handling, setup_registry_google_java_format call, and log formatting remain unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.4, 3.5_

  - [x] 3.5 Fix scripts/lib/langs/cpp.sh
    - Add `local _VERSION="${VER_CLANG_FORMAT:-}"` to `install_clang_format()`
    - Transform `run_mise install "${_PROVIDER:-}"` to `run_mise install "${_PROVIDER:-}@${_VERSION:-}"`
    - _Bug_Condition: isBugCondition(installCall) where installCall matches 'run_mise install "${_PROVIDER:-}"' without version suffix_
    - _Expected_Behavior: All install calls SHALL include @${_VERSION:-} suffix to enforce version locking from versions.sh_
    - _Preservation: Fast-path checks, DRY_RUN mode, error handling, and log formatting remain unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.4, 3.5_

  - [x] 3.6 Fix scripts/lib/langs/lua.sh
    - Add `local _VERSION="${VER_STYLUA:-}"` to `install_stylua()`
    - Transform `run_mise install "${_PROVIDER:-}"` to `run_mise install "${_PROVIDER:-}@${_VERSION:-}"`
    - _Bug_Condition: isBugCondition(installCall) where installCall matches 'run_mise install "${_PROVIDER:-}"' without version suffix_
    - _Expected_Behavior: All install calls SHALL include @${_VERSION:-} suffix to enforce version locking from versions.sh_
    - _Preservation: Fast-path checks, DRY_RUN mode, error handling, and log formatting remain unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.4, 3.5_

  - [x] 3.7 Fix scripts/lib/langs/ruby.sh
    - Add `local _VERSION` extraction logic to `setup_registry_rubocop()`
    - Transform `run_mise install "${_PROVIDER:-}"` to `run_mise install "${_PROVIDER:-}@${_VERSION:-}"`
    - Note: Rubocop uses gem provider, version may need extraction from gem specification
    - _Bug_Condition: isBugCondition(installCall) where installCall matches'run_mise install "${_PROVIDER:-}"' without version suffix_
    - _Expected_Behavior: All install calls SHALL include @${_VERSION:-} suffix to enforce version locking from versions.sh_
    - _Preservation: Fast-path checks, DRY_RUN mode, error handling, and log formatting remain unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.4, 3.5_

  - [x] 3.8 Fix scripts/lib/langs/runner.sh
    - Add `local _VERSION="${VER_JUST:-}"` to `install_just()`
    - Transform `run_mise install "${_PROVIDER:-}"` to `run_mise install "${_PROVIDER:-}@${_VERSION:-}"`
    - Add
All install calls SHALL include @${_VERSION:-} suffix to enforce version locking from versions.sh_
    - _Preservation: Fast-path checks, DRY_RUN mode, error handling, and log formatting remain unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.4,
3.5_

  - [x] 3.9 Fix scripts/lib/langs/security.sh
    - Add `local _VERSION="${VER_OSV_SCANNER:-}"` to `install_osv_scanner()`
    - Transform `run_mise install "${_PROVIDER:-}"` to `run_mise install "${_PROVIDER:-}@${_VERSION:-}"`
    - Add `local _VERSION=
"${VER_ZIZMOR:-}"` to `install_zizmor()`
    - Transform `run_mise install "${_PROVIDER:-}"` to `run_mise install "${_PROVIDER:-}@${_VERSION:-}"`
    - Add `local _VERSION="${VER_CARGO_AUDIT:-}"` to `install_cargo_audit()`
    - Transform `run_mise install "${_PROVIDER:-}"` to `run_mise install "${_PROVIDER:-}@${_VERSION:-}"`
    - _Bug_Condition: isBugCondition(installCall) where installCall matches 'run_mise install "${_PROVIDER:-}"' without version suffix_
    - _Expected_Behavior: All install calls SHALL include @${_VERSION:-} suffix to enforce version locking from versions.sh_
    - _Preservation: Fast-path checks, DRY_RUN mode, error handling, and log formatting remain unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.4, 3.5_

  - [x] 3.10 Fix scripts/lib/langs/terraform.sh
    - Add `local _VERSION="${VER_TFLINT:-}"` to `install_tflint()`
    - Transform `run_mise install "${_PROVIDER:-}"` to `run_mise install "${_PROVIDER:-}@${_VERSION:-}"`
    - _Bug_Condition: isBugCondition(installCall) where installCall matches 'run_mise install "${_PROVIDER:-}"' without version suffix_
    - _Expected_Behavior: All install calls SHALL include @${_VERSION:-} suffix to enforce version locking from versions.sh_
    - _Preservation: Fast-path checks, DRY_RUN mode, error handling, and log formatting remain unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.4, 3.5_

  - [x] 3.11 Fix scripts/lib/langs/openapi.sh
    - Add `local _VERSION="${VER_SPECTRAL:-}"` to `install_spectral()`
    - Transform `run_mise install "${_PROVIDER:-}"` to `run_mise install "${_PROVIDER:-}@${_VERSION:-}"`
    - _Bug_Condition: isBugCondition(installCall) where installCall matches 'run_mise install "${_PROVIDER:-}"' without version suffix_
    - _Expected_Behavior: All install calls SHALL include @${_VERSION:-} suffix to enforce version locking from versions.sh_
    - _Preservation: Fast-path checks, DRY_RUN mode, error handling, and log formatting remain unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.4, 3.5_

  - [x] 3.12 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Version Locking Enforcement
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1
    - **EXPECTED OUTCOME**: Test PASSES (confirms bug is fixed)
    - Verify all affected tools now install pinned versions from versions.sh
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [x] 3.13 Verify preservation tests still pass
    - **Property 2: Preservation** - Existing Installation Behavior
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm all tests still pass after fix (no regressions)
    - Verify fast-path checks, DRY_RUN mode, error handling remain functional
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 4. Checkpoint - Ensure all tests pass
  - Run all exploration and preservation tests
  - Verify all affected tools install correct pinned versions
  - Verify no regressions in existing installation patterns
  - Ensure reproducibility across multiple runs
  - Ask the user if questions arise

