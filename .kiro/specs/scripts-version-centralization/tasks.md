# Implementation Plan

- [x] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - Hardcoded Provider Detection
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate hardcoded provider values exist across the codebase
  - **Scoped PBT Approach**: Search for all instances of `local _PROVIDER="[^$]+"` pattern in `scripts/lib/langs/*.sh` files
  - Test implementation: Use grep/ripgrep to find hardcoded `_PROVIDER` assignments
  - Expected counterexamples on UNFIXED code:
    - GitHub providers: ~20 instances (e.g., `local _PROVIDER="github:hadolint/hadolint"`)
    - NPM providers: ~10 instances (e.g., `local _PROVIDER="npm:prettier"`)
    - Pipx providers: ~5 instances (e.g., `local _PROVIDER="pipx:sqlfluff"`)
    - Gem providers: ~1 instance (e.g., `local _PROVIDER="gem:rubocop"`)
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS with 36 hardcoded instances found (this is correct - it proves the bug exists)
  - Document all counterexamples found to understand scope
  - Verify findings match the 36 instances documented in bugfix.md
  - Mark task complete when test is written, run, and all 36 failures are documented
  - _Requirements: 1.1-1.36_

- [x] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Existing Functionality Preservation
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for scripts that already use centralized variables correctly
  - Test cases to observe and preserve:
    - Version checking: `get_mise_tool_version "${_PROVIDER:-}"` works correctly
    - Installation: `run_mise install "${_PROVIDER:-}"` executes properly
    - Logging: `_log_setup` and `log_summary` display correct provider info
    - DRY_RUN mode: Preview functionality works without executing installations
    - Fast-path: `is_version_match` skips unnecessary installations
    - Language detection: `has_lang_files` skips when no relevant files exist
    - Error handling: Failures are handled gracefully
  - Write property-based tests capturing observed behavior patterns from Preservation Requirements
  - Property-based testing generates many test cases for stronger guarantees
  - Test scripts that already use centralized pattern (security.sh, java.sh, kotlin.sh, testing.sh)
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1-3.10_

- [ ] 3. Fix for hardcoded provider centralization

  - [x] 3.1 Add missing provider variables to versions.sh
    - Add `VER_EDITORCONFIG_CHECKER_PROVIDER="github:editorconfig-checker/editorconfig-checker"` in the quality tooling section
    - Add `VER_SWIFTFORMAT_PROVIDER="github:nicklockwood/SwiftFormat"` in the language tooling section
    - Add `VER_RUBOCOP_PROVIDER="gem:rubocop"` in the language tooling section
    - Ensure variables follow naming convention: `VER_TOOLNAME_PROVIDER`
    - Place variables in appropriate sections for maintainability
    - _Bug_Condition: isBugCondition(line) where line contains hardcoded provider and corresponding centralized variable is missing_
    - _Expected_Behavior: All referenced provider variables exist in versions.sh_
    - _Preservation: Existing variables and structure in versions.sh remain unchanged_
    - _Requirements: 2.11, 2.26, 2.35_

  - [x] 3.2 Replace hardcoded providers in shell.sh (3 instances)
    - Replace `local _PROVIDER="github:mvdan/sh"` with `local _PROVIDER="${VER_SHFMT_PROVIDER:-}"` in install_shfmt
    - Replace `local _PROVIDER="github:koalaman/shellcheck"` with `local _PROVIDER="${VER_SHELLCHECK_PROVIDER:-}"` in install_shellcheck
    - Replace `local _PROVIDER="github:rhysd/actionlint"` with `local _PROVIDER="${VER_ACTIONLINT_PROVIDER:-}"` in install_actionlint
    - Preserve the `:-` fallback pattern for robustness
    - _Bug_Condition: isBugCondition(line) where line in shell.sh contains hardcoded provider_
    - _Expected_Behavior: All provider assignments use centralized variables from versions.sh_
    - _Preservation: All other logic in shell.sh remains unchanged_
    - _Requirements: 2.1, 2.5, 2.6_

  - [x] 3.3 Replace hardcoded providers in docker.sh (2 instances)
    - Replace `local _PROVIDER="github:hadolint/hadolint"` with `local _PROVIDER="${VER_HADOLINT_PROVIDER:-}"` in install_hadolint
    - Replace `local _PROVIDER="npm:dockerfile-utils"` with `local _PROVIDER="${VER_DOCKERFILE_UTILS_PROVIDER:-}"` in install_dockerfile_utils
    - _Bug_Condition: isBugCondition(line) where line in docker.sh contains hardcoded provider_
    - _Expected_Behavior: All provider assignments use centralized variables_
    - _Preservation: Installation and version checking logic unchanged_
    - _Requirements: 2.2, 2.8_

  - [x] 3.4 Replace hardcoded providers in runner.sh (2 instances)
    - Replace `local _PROVIDER="github:casey/just"` with `local _PROVIDER="${VER_JUST_PROVIDER:-}"` in install_just
    - Replace `local _PROVIDER="github:go-task/task"` with `local _PROVIDER="${VER_TASK_PROVIDER:-}"` in install_task
    - _Bug_Condition: isBugCondition(line) where line in runner.sh contains hardcoded provider_
    - _Expected_Behavior: All provider assignments use centralized variables_
    - _Preservation: Task runner installation logic unchanged_
    - _Requirements: 2.3, 2.7_

  - [x] 3.5 Replace hardcoded providers in lua.sh (1 instance)
    - Replace `local _PROVIDER="github:JohnnyMorganz/StyLua"` with `local _PROVIDER="${VER_STYLUA_PROVIDER:-}"` in install_stylua
    - _Bug_Condition: isBugCondition(line) where line in lua.sh contains hardcoded provider_
    - _Expected_Behavior: Provider assignment uses centralized variable_
    - _Preservation: Lua tooling installation unchanged_
    - _Requirements: 2.4_

  - [x] 3.6 Replace hardcoded providers in base.sh (4 instances)
    - Replace `local _PROVIDER="github:gitleaks/gitleaks"` with `local _PROVIDER="${VER_GITLEAKS_PROVIDER:-}"` in install_gitleaks
    - Replace `local _PROVIDER="github:mrtazz/checkmake"` with `local _PROVIDER="${VER_CHECKMAKE_PROVIDER:-}"` in install_checkmake
    - Replace `local _PROVIDER="github:editorconfig-checker/editorconfig-checker"` with `local _PROVIDER="${VER_EDITORCONFIG_CHECKER_PROVIDER:-}"` in install_editorconfig_checker
    - Replace `local _PROVIDER="github:goreleaser/goreleaser"` with `local _PROVIDER="${VER_GORELEASER_PROVIDER:-}"` in install_goreleaser
    - _Bug_Condition: isBugCondition(line) where line in base.sh contains hardcoded provider_
    - _Expected_Behavior: All provider assignments use centralized variables_
    - _Preservation: Base tooling installation logic unchanged_
    - _Requirements: 2.9, 2.10, 2.11, 2.12_

  - [x] 3.7 Replace hardcoded providers in toml.sh (1 instance)
    - Replace `local _PROVIDER="npm:@taplo/cli"` with `local _PROVIDER="${VER_TAPLO_PROVIDER:-}"` in install_taplo
    - _Bug_Condition: isBugCondition(line) where line in toml.sh contains hardcoded provider_
    - _Expected_Behavior: Provider assignment uses centralized variable_
    - _Preservation: TOML tooling installation unchanged_
    - _Requirements: 2.13_

  - [x] 3.8 Replace hardcoded providers in helm.sh (1 instance)
    - Replace `local _PROVIDER="github:stackrox/kube-linter"` with `local _PROVIDER="${VER_KUBE_LINTER_PROVIDER:-}"` in install_kube_linter
    - _Bug_Condition: isBugCondition(line) where line in helm.sh contains hardcoded provider_
    - _Expected_Behavior: Provider assignment uses centralized variable_
    - _Preservation: Kubernetes linting logic unchanged_
    - _Requirements: 2.14_

  - [x] 3.9 Replace hardcoded providers in node.sh (7 instances)
    - Replace `local _PROVIDER="npm:sort-package-json"` with `local _PROVIDER="${VER_SORT_PACKAGE_JSON_PROVIDER:-}"` in install_sort_package_json
    - Replace `local _PROVIDER="npm:eslint"` with `local _PROVIDER="${VER_ESLINT_PROVIDER:-}"` in install_eslint
    - Replace `local _PROVIDER="npm:stylelint"` with `local _PROVIDER="${VER_STYLELINT_PROVIDER:-}"` in install_stylelint
    - Replace `local _PROVIDER="npm:vitepress"` with `local _PROVIDER="${VER_VITEPRESS_PROVIDER:-}"` in install_vitepress
    - Replace `local _PROVIDER="npm:prettier"` with `local _PROVIDER="${VER_PRETTIER_PROVIDER:-}"` in install_prettier
    - Replace `local _PROVIDER="npm:@commitlint/cli"` with `local _PROVIDER="${VER_COMMITLINT_PROVIDER:-}"` in install_commitlint
    - Replace `local _PROVIDER="npm:commitizen"` with `local _PROVIDER="${VER_COMMITIZEN_PROVIDER:-}"` in install_commitizen
    - _Bug_Condition: isBugCondition(line) where line in node.sh contains hardcoded provider_
    - _Expected_Behavior: All provider assignments use centralized variables_
    - _Preservation: Node.js tooling installation logic unchanged_
    - _Requirements: 2.15, 2.16, 2.17, 2.18, 2.19, 2.20, 2.21_

  - [x] 3.10 Replace hardcoded providers in sql.sh (1 instance)
    - Replace `local _PROVIDER="pipx:sqlfluff"` with `local _PROVIDER="${VER_SQLFLUFF_PROVIDER:-}"` in install_sqlfluff
    - _Bug_Condition: isBugCondition(line) where line in sql.sh contains hardcoded provider_
    - _Expected_Behavior: Provider assignment uses centralized variable_
    - _Preservation: SQL linting logic unchanged_
    - _Requirements: 2.22_

  - [x] 3.11 Replace hardcoded providers in protobuf.sh (1 instance)
    - Replace `local _PROVIDER="github:bufbuild/buf"` with `local _PROVIDER="${VER_BUF_PROVIDER:-}"` in install_buf
    - _Bug_Condition: isBugCondition(line) where line in protobuf.sh contains hardcoded provider_
    - _Expected_Behavior: Provider assignment uses centralized variable_
    - _Preservation: Protobuf tooling installation unchanged_
    - _Requirements: 2.23_

  - [x] 3.12 Replace hardcoded providers in markdown.sh (1 instance)
    - Replace `local _PROVIDER="npm:markdownlint-cli2"` with `local _PROVIDER="${VER_MARKDOWNLINT_PROVIDER:-}"` in install_markdownlint
    - _Bug_Condition: isBugCondition(line) where line in markdown.sh contains hardcoded provider_
    - _Expected_Behavior: Provider assignment uses centralized variable_
    - _Preservation: Markdown linting logic unchanged_
    - _Requirements: 2.24_

  - [x] 3.13 Replace hardcoded providers in rego.sh (1 instance)
    - Replace `local _PROVIDER="github:open-policy-agent/opa"` with `local _PROVIDER="${VER_OPA_PROVIDER:-}"` in install_opa
    - _Bug_Condition: isBugCondition(line) where line in rego.sh contains hardcoded provider_
    - _Expected_Behavior: Provider assignment uses centralized variable_
    - _Preservation: OPA policy checking logic unchanged_
    - _Requirements: 2.25_

  - [x] 3.14 Replace hardcoded providers in swift.sh (2 instances)
    - Replace `local _PROVIDER="github:nicklockwood/SwiftFormat"` with `local _PROVIDER="${VER_SWIFTFORMAT_PROVIDER:-}"` in install_swiftformat
    - Replace `local _PROVIDER="github:realm/SwiftLint"` with `local _PROVIDER="${VER_SWIFTLINT_PROVIDER:-}"` in install_swiftlint
    - _Bug_Condition: isBugCondition(line) where line in swift.sh contains hardcoded provider_
    - _Expected_Behavior: All provider assignments use centralized variables_
    - _Preservation: Swift tooling installation logic unchanged_
    - _Requirements: 2.26, 2.27_

  - [x] 3.15 Replace hardcoded providers in python.sh (2 instances)
    - Replace `local _PROVIDER="github:astral-sh/ruff"` with `local _PROVIDER="${VER_RUFF_PROVIDER:-}"` in install_ruff
    - Replace `local _PROVIDER="pipx:pip-audit"` with `local _PROVIDER="${VER_PIP_AUDIT_PROVIDER:-}"` in install_pip_audit
    - _Bug_Condition: isBugCondition(line) where line in python.sh contains hardcoded provider_
    - _Expected_Behavior: All provider assignments use centralized variables_
    - _Preservation: Python tooling installation logic unchanged_
    - _Requirements: 2.28, 2.29_

  - [x] 3.16 Replace hardcoded providers in yaml.sh (2 instances)
    - Replace `local _PROVIDER="pipx:yamllint"` with `local _PROVIDER="${VER_YAMLLINT_PROVIDER:-}"` in install_yamllint
    - Replace `local _PROVIDER="github:dotenv-linter/dotenv-linter"` with `local _PROVIDER="${VER_DOTENV_LINTER_PROVIDER:-}"` in install_dotenv_linter
    - _Bug_Condition: isBugCondition(line) where line in yaml.sh contains hardcoded provider_
    - _Expected_Behavior: All provider assignments use centralized variables_
    - _Preservation: YAML linting logic unchanged_
    - _Requirements: 2.30, 2.31_

  - [x] 3.17 Replace hardcoded providers in openapi.sh (1 instance)
    - Replace `local _PROVIDER="npm:@stoplight/spectral-cli"` with `local _PROVIDER="${VER_SPECTRAL_PROVIDER:-}"` in install_spectral
    - _Bug_Condition: isBugCondition(line) where line in openapi.sh contains hardcoded provider_
    - _Expected_Behavior: Provider assignment uses centralized variable_
    - _Preservation: OpenAPI validation logic unchanged_
    - _Requirements: 2.32_

  - [x] 3.18 Replace hardcoded providers in terraform.sh (1 instance)
    - Replace `local _PROVIDER="github:terraform-linters/tflint"` with `local _PROVIDER="${VER_TFLINT_PROVIDER:-}"` in install_tflint
    - _Bug_Condition: isBugCondition(line) where line in terraform.sh contains hardcoded provider_
    - _Expected_Behavior: Provider assignment uses centralized variable_
    - _Preservation: Terraform linting logic unchanged_
    - _Requirements: 2.33_

  - [x] 3.19 Replace hardcoded providers in cpp.sh (1 instance)
    - Replace `local _PROVIDER="pipx:clang-format"` with `local _PROVIDER="${VER_CLANG_FORMAT_PROVIDER:-}"` in install_clang_format
    - _Bug_Condition: isBugCondition(line) where line in cpp.sh contains hardcoded provider_
    - _Expected_Behavior: Provider assignment uses centralized variable_
    - _Preservation: C++ formatting logic unchanged_
    - _Requirements: 2.34_

  - [x] 3.20 Replace hardcoded providers in ruby.sh (1 instance)
    - Replace `local _PROVIDER="gem:rubocop"` with `local _PROVIDER="${VER_RUBOCOP_PROVIDER:-}"` in install_rubocop
    - _Bug_Condition: isBugCondition(line) where line in ruby.sh contains hardcoded provider_
    - _Expected_Behavior: Provider assignment uses centralized variable_
    - _Preservation: Ruby linting logic unchanged_
    - _Requirements: 2.35_

  - [x] 3.21 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - No Hardcoded Providers Remain
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior (no hardcoded providers)
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1
    - Search for `local _PROVIDER="[^$]+"` pattern in all `scripts/lib/langs/*.sh` files
    - **EXPECTED OUTCOME**: Test PASSES with zero hardcoded instances found (confirms bug is fixed)
    - Verify all 36 instances have been replaced with centralized variables
    - Verify all centralized variables exist in versions.sh
    - Verify variable naming follows convention (VER_TOOLNAME_PROVIDER)
    - Verify fallback pattern `:-` is preserved in all references
    - _Requirements: Expected Behavior Properties from design (2.1-2.36)_

  - [x] 3.22 Verify preservation tests still pass
    - **Property 2: Preservation** - Existing Functionality Unchanged
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2
    - Test that version checking with `get_mise_tool_version "${_PROVIDER:-}"` works identically
    - Test that installation with `run_mise install "${_PROVIDER:-}"` executes correctly
    - Test that logging with `_log_setup` and `log_summary` displays correct info
    - Test that DRY_RUN mode preview functionality works identically
    - Test that fast-path `is_version_match` logic continues to work
    - Test that language detection `has_lang_files` continues to work
    - Test that error handling behaves identically
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm all tests still pass after fix (no regressions)
    - _Requirements: Preservation Requirements from design (3.1-3.10)_

- [x] 4. Checkpoint - Ensure all tests pass
  - Verify bug condition test passes (no hardcoded providers remain)
  - Verify preservation tests pass (no regressions in existing functionality)
  - Verify all 36 instances have been centralized
  - Verify 3 missing variables added to versions.sh
  - Run smoke test: source versions.sh and verify all VER_*_PROVIDER variables are defined
  - Ask the user if questions arise or if additional validation is needed

