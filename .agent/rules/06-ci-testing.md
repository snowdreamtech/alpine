# CI & Testing Guidelines

> Objective: Unify test scope, quality thresholds, CI behavior, and gating strategy for all projects.

## 1. Test Types & Coverage

- All projects **MUST** include unit tests and integration tests. End-to-end (E2E) tests are required for all user-facing flows and critical happy paths.
- Set coverage targets for critical paths. Coverage is a signal, not the sole quality metric — prioritize meaningful tests over inflating numbers with trivial assertions:
  - Core business logic: ≥ 80% line and branch coverage
  - Critical security paths (auth, payments): ≥ 95%
  - UI components: ≥ 70% (supplemented by visual regression tests)
- Use **table-driven or parameterized tests** to cover edge cases and boundary conditions systematically:

  ```go
  // Go table-driven test pattern
  tests := []struct {
    name    string
    input   string
    want    int
    wantErr bool
  }{
    {"valid input", "42", 42, false},
    {"empty string", "", 0, true},
    {"negative", "-1", -1, false},
    {"overflow", "99999999999", 0, true},
  }
  for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
      got, err := ParseAge(tt.input)
      if (err != nil) != tt.wantErr { t.Fatalf("wantErr=%v, got err=%v", tt.wantErr, err) }
      if got != tt.want { t.Errorf("want %d, got %d", tt.want, got) }
    })
  }
  ```

- Include **contract tests** (Pact, Spring Cloud Contract) for all service-to-service integrations. Consumer-driven contract tests MUST pass before publishing a new provider version.
- Include **performance benchmark tests** for latency and throughput-sensitive code paths. Track results over time and alert on regressions exceeding 10%.

## 2. CI Pipeline Requirements

- All PRs **MUST** pass CI (lint, unit tests, integration tests, static analysis, security scanning) before merging. Merging is prohibited when CI fails — no exceptions without documented override and incident report.
- The CI pipeline SHOULD strive for reproducibility. While **deterministic caching** (lockfile hash, OS, runtime version) is highly recommended for stable projects, this template intentionally avoids default caching to ensure universal compatibility:

  ```yaml
  # Optional: GitHub Actions — deterministic cache
  # - uses: actions/cache@v4
  #   with:
  #     path: ~/.npm
  #     key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
  #     restore-keys: ${{ runner.os }}-node-
  ```

- CI must complete within a reasonable time:
  - **Fast path** (lint + unit tests): < 5 minutes
  - **Full pipeline** (integration + E2E + security): < 30 minutes
  - Use **parallelism** (parallel jobs), **layer caching** (Docker), and **affected-only runs** (Nx, Turborepo) aggressively.
- Artifact traceability: every CI run MUST produce a build manifest linking: `source commit SHA` → `build artifacts` → `test results` → `scan reports`. Archive these for audit purposes.
- Configure CI to run on a **matrix** of OS/runtime versions for cross-platform projects:

  ```yaml
  strategy:
    matrix:
      os: [ubuntu-latest, macos-latest, windows-latest]
      node: [20, 22]
  runs-on: ${{ matrix.os }}
  ```

## 3. Test Data & Environments

- Use **reproducible, isolated test data**: factories, fixtures, or recorded snapshots. Never depend on production data, shared databases, or mutable external state:

  ```typescript
  // Factory pattern — deterministic test data
  const createUser = (overrides: Partial<User> = {}): User => ({
    id: crypto.randomUUID(),
    email: "test@example.com",
    role: "user",
    createdAt: new Date("2025-01-01T00:00:00Z"),
    ...overrides,
  });
  ```

- **PII in test data is strictly prohibited**. Anonymize or synthesize any data derived from production. Treat synthetic test data containing realistic PII patterns with the same controls as real PII.
- Use **Testcontainers** (or Docker Compose) for integration tests that require real databases, caches, or message queues — avoid mocking infrastructure at the integration level:

  ```java
  // Testcontainers — real PostgreSQL in tests
  @Container
  static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");
  ```

- Define a clear **test data lifecycle**: create in `beforeEach`/setup, clean up in `afterEach`/teardown. Tests MUST NOT leave persistent state that affects other tests.
- For cross-platform compatibility, run critical CI pipelines on at least **Linux and macOS** using matrix builds.

## 4. Fast Feedback Strategy

- Structure the pipeline in **progressive stages** — fast checks first, slow checks later:

  ```
  Stage 1 (< 3 min): lint, format, typecheck, unit tests
  Stage 2 (< 10 min): integration tests, contract tests
  Stage 3 (parallel): E2E tests, security scans, performance benchmarks
  ```

- Use **incremental/affected testing** where possible: only re-run tests for code paths affected by a change:
  - Monorepos: **Nx affected**, **Turborepo**, or **Bazel**
  - Python: **pytest-changed** (tests affected by changed files)
  - Languages with import analysis: selectively run test targets
- Report test results in **machine-readable format** (JUnit XML, TAP, CTRF) to enable dashboard tracking, trend analysis, and CI integration with test reporting tools:

  ```bash
  jest --reporters=jest-junit   # JUnit XML output
  pytest --junitxml=results.xml  # pytest JUnit output
  go test ./... -v 2>&1 | go-junit-report > results.xml  # Go
  ```

- Cache aggressively with **content-addressed keys** that include all relevant inputs:

  ```yaml
  key: ${{ runner.os }}-${{ matrix.node }}-${{ hashFiles('**/package-lock.json') }}-${{ hashFiles('src/**') }}
  ```

## 5. Quality Gates & Failure Policy

- Define explicit **quality gates** that block merge:
  - Linter errors (zero tolerance — must be clean)
  - Test failures (zero tolerance)
  - Coverage drop below threshold (configurable per project)
  - Security findings of HIGH or CRITICAL severity
  - Contract test failures (consumer-driven contracts)
  - Build failures or type errors
- **Flaky test policy**:
  - A test is **flaky** if it fails intermittently without code changes (timing issues, race conditions, order-dependent tests, network calls)
  - Flaky tests MUST be **quarantined** within 24 hours of detection:

    ```python
    @pytest.mark.skip(reason="Flaky — tracked in issue #456, owner: @alice")
    def test_sends_notification():
        ...
    ```

  - Quarantined flaky tests MUST be resolved within **2 weeks** (one sprint). Unresolved flakes escalate to the team lead.
  - Root-cause analysis required: fix the underlying race condition or non-determinism — do not simply retry the test.
- Major test failures **MUST** trigger notifications to the responsible team via the project's notification channel (Slack webhook, PagerDuty, email).
- Post-merge failures in `main` or `develop` are **P1 incidents** — the team MUST stop new feature work and restore green CI before continuing. Revert the offending commit if a fix is not immediately available.

## 6. Branch-Specific Workflow Strategy

To balance **development velocity**, **release stability**, and **security**, the CI/CD architecture is split into two distinct modes based on branch type, using secure **Job Dependencies (`needs`)** instead of risky `workflow_run` triggers.

### 6.1 Development Flow (Non-Main)

Designed for high-frequency iteration on `feat/**`, `fix/**`, and `dev` branches.

- **CI Trigger**: Triggered ONLY on `pull_request` (targeting `main` or `dev`).
- **Goal**: Rapid feedback to ensure code is "Merge-Ready" before it reaches core branches.
- **Job Dependency Chaining**: Uses internal `needs` to chain `lint` → `test` → `audit` within a single `ci.yml`.
- **Security & Isolation**: Since it runs in the PR context, it is naturally isolated from the `main` branch secrets and environment.
- **Fail-Fast Principle**: Each stage only runs if the previous one succeeds. This prevents expensive tests or audits from running on code that fails basic linting.

### 6.2 Release Flow (Main & Tags)

Designed for absolute stability and zero-redundancy distribution on the `main` branch.

- **CD Trigger (Main)**: Triggered on `push to main`.
- **Job Chaining**: Uses `needs` to chain `verify` → `release-please` within a single `cd.yml`.
- **Atomic Verification**: `release-please` (which creates version bumps and tags) only executes if the full `make verify` check passes on the actual `main` branch.
- **Distribution (Tags)**: `GoReleaser` is triggered **ONLY** by the **Git Tag** (v*) generated by Release Please.
- **Zero Redundancy**: Distribution workflows MUST NOT re-run verification jobs; they must trust the existing `main` verification results.
- **Automated Rollback**: Release workflows MUST include cleanup logic (e.g., deleting partial releases/tags) if the distribution fails.

### 6.3 Unified Entry Point (Makefile)

All CI workflows **MUST** invoke logic through `Makefile` targets rather than direct script calls. This ensures:

- **Local-CI Parity**: Developers can run `make verify` locally to get the exact same result as the CI.
- **Health Checks**: Every workflow initialization MUST include `make check-env` to validate the runner environment before execution.

### 6.4 Matrix vs. Primary Runner Philosophy

To optimize CI/CD performance and credit usage while maintaining high assurance:

- **Tier 1 (Matrix - All OSs)**: Functional verification (`test`, `lint`) MUST run on a matrix (Windows, Mac, Linux) to ensure cross-platform compatibility.
- **Tier 2 (Primary - Ubuntu Only)**: Logical, secure, and metadata-heavy tasks (`audit`, `Commitlint`, `Zizmor`, `SARIF Upload`) MUST run ONLY on the primary `ubuntu-latest` runner. This prevents duplicate SARIF findings and conserves resources where platform-specific behavior is irrelevant.

### 6.5 Token Management & Automation Security

To ensure seamless automation flow (Chain-Triggering) and resilience against GitHub API rate limits:

- **Token Fallback Pattern**: All critical automation steps (Release, Sync, History-heavy setup) MUST use the pattern: `token: ${{ secrets.WORKFLOW_SECRET || secrets.GITHUB_TOKEN }}`.
- **Why WORKFLOW_SECRET?**:
    - **Triggering**: Actions triggered by `GITHUB_TOKEN` do NOT trigger other workflows. To enable chain-triggering (e.g., `release-please` triggering `goreleaser`), an elevated Personal Access Token (stored as `WORKFLOW_SECRET`) MUST be used.
    - **Bypassing Protection**: Allows automated pushes to bypass branch protection where necessary.
    - **Rate Limits**: Authenticated requests via PAT provide significantly higher API rate limits than the default token.
    - **Minimal Privilege**: For Read-only/Unit-test jobs that do not need to trigger follow-on workflows, always use the default `GITHUB_TOKEN` to adhere to the principle of least privilege.

### 6.6 Single Source of Truth (SSoT) Check Model

To eliminate redundant CI/CD execution and maximize resource efficiency, the project follows a strict **"Check-before-Merge"** and **"Deliver-on-Push"** separation:

- **CI (Integration Check)**: Triggered ONLY on `pull_request` (targeting `main` or `dev`).
    - **Goal**: Rapid feedback to ensure code is "Merge-Ready".
- **CD (Delivery Check)**: Triggered ONLY on `push` to core branches (`main`, `dev`). (Explicitly NOT triggered on `pull_request`).
    - **Goal**: Final baseline verification of the integrated code + Artifact Delivery (Release, Docker, etc.).
- **Rationale**: Since code arriving on core branches has already passed CI during the PR phase, we do NOT trigger CI on `push`. Instead, CD performs a final integrity check before proceeding to delivery, avoiding any duplication of work during the PR stage.

### 6.7 Unified Release Orchestration

All core integration and stability branches MUST follow a unified release standard to ensure traceability:

- **Core Branches**: Both `main` (Stable) and `dev` (Beta/Integration) are considered primary.
- **Release Please**: Every push to a Core Branch MUST trigger `release-please` orchestration to automate versioning, changelog generation, and Gitleaks/Security auditing.
- **Delivery Parity**: Whether on `main` or `dev`, the delivery pipeline (CD) must ensure 100% parity in verification depth (Lint -> Test -> Audit).

## 7. Tool Installation & Atomic Verification

To ensure CI reliability and prevent silent failures where tools are "installed" but not actually usable, all tool installation functions **MUST** implement atomic verification.

### 7.1 The Five-Step Atomic Verification Pattern

Every tool installation in CI **MUST** verify the tool is fully functional through these five atomic checks:

```bash
verify_tool_atomic() {
  local _TOOL_NAME="${1:-}"
  local _VERSION_FLAG="${2:---version}"

  # Step 1: Check mise registration
  if ! mise list | grep -q "${_TOOL_NAME}"; then
    log_error "Step 1/5 Failed: ${_TOOL_NAME} not registered in mise"
    return 1
  fi

  # Step 2: Check binary existence (command -v)
  if ! command -v "${_TOOL_NAME}" >/dev/null 2>&1; then
    log_error "Step 2/5 Failed: ${_TOOL_NAME} not found via command -v"
    return 1
  fi

  # Step 3: Check path resolution (resolve_bin)
  local _RESOLVED_PATH
  if ! _RESOLVED_PATH=$(resolve_bin "${_TOOL_NAME}"); then
    log_error "Step 3/5 Failed: Cannot resolve path for ${_TOOL_NAME}"
    return 1
  fi

  # Step 4: Check executability (test -x)
  if [ ! -x "${_RESOLVED_PATH}" ]; then
    log_error "Step 4/5 Failed: ${_TOOL_NAME} at ${_RESOLVED_PATH} is not executable"
    return 1
  fi

  # Step 5: Run smoke test (--version with timeout)
  if ! run_with_timeout_robust 5 "${_TOOL_NAME}" "${_VERSION_FLAG}" >/dev/null 2>&1; then
    log_error "Step 5/5 Failed: ${_TOOL_NAME} smoke test failed"
    return 1
  fi

  return 0
}
```

### 7.2 Installation Function Pattern

All tool installation functions **MUST** follow this pattern:

```bash
install_tool() {
  local _T0=$(date +%s)
  local _TITLE="Tool Name"
  local _PROVIDER="${VER_TOOL_PROVIDER:-}"
  local _VERSION="${VER_TOOL:-}"

  # Fast-path: Check if already installed
  local _CUR_VER=$(get_version tool)
  if is_version_match "${_CUR_VER:-}" "${_VERSION:-}"; then
    log_summary "Category" "Tool" "✅ Exists" "${_CUR_VER:-}" "0"
    return 0
  fi

  _log_setup "${_TITLE:-}" "${_PROVIDER:-}"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Category" "Tool" '⚖️ Previewed' "-" '0'
    return 0
  fi

  # Install via mise
  local _STAT="✅ mise"
  run_mise install "${_PROVIDER:-}@${_VERSION:-}" || _STAT="❌ Failed"

  # CRITICAL: Atomic verification
  if ! verify_tool_atomic "tool" "--version"; then
    _STAT="❌ Not Executable"
    log_summary "Category" "Tool" "${_STAT:-}" "-" "$(($(date +%s) - _T0))"
    [ "${CI:-}" = "true" ] && return 1  # Fail-fast in CI
    return 0  # Warn-continue in local dev
  fi

  log_summary "Category" "Tool" "${_STAT:-}" "$(get_version tool)" "$(($(date +%s) - _T0))"
}
```

### 7.3 Key Principles

- **Fail-Fast in CI**: When verification fails in CI (`CI=true`), the function **MUST** return error code 1 immediately to prevent wasted CI time.
- **Warn-Continue Locally**: In local development, verification failures should log a warning but return 0 to allow developers to continue working.
- **Timeout Protection**: All tool execution calls **MUST** use `run_with_timeout_robust` (default: 5 seconds) to prevent indefinite hangs.
- **Cross-Platform Binary Detection**: Binary detection **MUST** handle platform-specific patterns:
  - Windows: Check for `.exe` extensions
  - Alternative naming: Check for tool-specific patterns (e.g., `ec-*` for editorconfig-checker)
- **Atomic Commits**: Each batch of tool fixes **MUST** be committed atomically with clear, descriptive commit messages following Conventional Commits.

### 7.4 Error Handling Requirements

- **Clear Error Messages**: Every verification failure **MUST** log which step failed and why:
  ```
  [ERROR] Step 3/5 Failed: Cannot resolve path for shfmt
  [ERROR] shfmt installed but failed atomic verification
  ```

- **Detailed Debug Output**: In CI, enable debug logging to show verification progress:
  ```
  [DEBUG] === Atomic Verification: Shfmt ===
  [DEBUG] Step 1/5: Checking mise registration... ✓
  [DEBUG] Step 2/5: Checking binary existence... ✓
  [DEBUG] Step 3/5: Checking path resolution... ✓
  [DEBUG] Step 4/5: Checking executability... ✓
  [DEBUG] Step 5/5: Running smoke test... ✓
  [DEBUG] === ✓ Shfmt fully verified ===
  ```

- **Status Reporting**: Use consistent status indicators in log summaries:
  - `✅ Exists` - Tool already installed and verified
  - `✅ mise` - Tool successfully installed via mise
  - `❌ Failed` - Installation failed
  - `❌ Not Executable` - Installed but failed atomic verification
  - `⚖️ Previewed` - Dry-run mode

### 7.5 Maintenance Guidelines

When adding new tools:

1. **Use the atomic verification pattern** shown in §7.2
2. **Test locally first**: Run `make setup` to verify no regressions
3. **Test in CI**: Push to a test branch and verify CI passes on all platforms (Linux, macOS, Windows)
4. **Verify error scenarios**: Temporarily break mise to ensure error handling works correctly
5. **Commit atomically**: Group related tool fixes together with descriptive commit messages

### 7.6 Common Pitfalls to Avoid

- ❌ **Don't** assume a tool is usable just because `mise install` succeeded
- ❌ **Don't** skip timeout protection on tool execution calls
- ❌ **Don't** use different error handling patterns for different tools
- ❌ **Don't** commit verification failures without fixing the root cause
- ✅ **Do** verify tools are fully functional before marking installation as successful
- ✅ **Do** use consistent error codes (return 1 in CI, return 0 locally)
- ✅ **Do** provide clear, actionable error messages
- ✅ **Do** test on all target platforms before merging

## 8. CI Security & Supply Chain

- **Immutable Action Pinning (SHA-1) - GOLD STANDARD**: All GitHub Actions references **MUST** use the 40-character commit SHA (e.g., `uses: actions/checkout@1d96...`). This is the only way to guarantee that the code being executed is the exact version that was audited.
  - Tags (even exact versions like `v6.0.2`) are mutable and can be hijacked.
  - SHAs are immutable and provide cryptographic proof of integrity.

  ```yaml
  # ✅ GOLD STANDARD — Immutable SHA-1 pinning
  - uses: actions/checkout@1d96c3a830132f11fdf16401030e64f2b380ed33 # v6.0.2
  - uses: actions/setup-node@1d0ff469b7ec7b3c67d9115c28d015357348bd0a # v6.3.0
  ```

  Use `dependabot` (with `version-updates` for GitHub Actions) to automatically track and update these SHAs.

- Use **OIDC (OpenID Connect)** for short-lived cloud credentials in CI instead of long-lived static secrets:

  ```yaml
  # GitHub Actions OIDC — no stored AWS credentials
  permissions:
    id-token: write
    contents: read

  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456789:role/github-actions-deploy
      aws-region: us-east-1
  ```

- Apply **least-privilege permissions** to every CI workflow. Only grant the minimum `permissions` required:

  ```yaml
  permissions:
    contents: read # read source only
    pages: write # only if deploying to GitHub Pages
    id-token: write # only if using OIDC
  ```

- Sign build artifacts and container images in CI using **Sigstore/cosign**:

  ```bash
  cosign sign --yes "$IMAGE_DIGEST"
  cosign verify --certificate-identity-regexp=".*" \
    --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
    "$IMAGE_DIGEST"
  ```

- Run **secret scanning** as the first step in every CI pipeline, before any code builds:

  ```bash
  # Set rename limit to suppress git performance warning on large repos
  git config diff.renameLimit 4000
  gitleaks detect --source . --config .gitleaks.toml
  ```

  See `04-security.md §2` for the full Gitleaks configuration best practices and path exclusion decision matrix.

- For SAST tools installed via `pip` (e.g., Semgrep), be aware of **Python 3.12 compatibility**: Semgrep ≥ v1.x requires `setuptools` (`pkg_resources`) which is no longer bundled with Python 3.12. Fix: install `setuptools` alongside semgrep.

  ```yaml
  - name: Run Semgrep
    run: |
      pip install --quiet semgrep setuptools
      semgrep scan --config=auto --error --exclude=.git --exclude=node_modules || true
  ```

  > **Note**: `semgrep/semgrep-action` was archived on 2024-04-09 and is no longer maintained. Do not use it.
