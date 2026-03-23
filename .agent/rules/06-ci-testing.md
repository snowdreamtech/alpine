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

To balance **development velocity** and **release stability**, the CI/CD architecture is split into two distinct modes based on the branch type.

### 6.1 Development Flow (Non-Main)

Designed for high-frequency iteration on `feat/**`, `fix/**`, and `dev` branches.

- **CI Trigger**: Every `push` or `PR` update.
- **Sequential Chaining**: Uses `workflow_run` to chain `Code Quality` (Lint) → `Unit Testing` → `Security Audit`.
- **CD Trigger (Preview)**: Optional deployment to a temporary/preview environment **ONLY** after all CI stages succeed.
- **Fail-Fast Principle**: Each stage only runs if the previous one succeeds. This prevents expensive tests or audits from running on code that fails basic linting.

### 6.2 Release Flow (Main & Tags)

Designed for absolute stability and zero-redundancy distribution on the `main` branch.

- **CI Trigger (Gate)**: Triggered on `push to main`. Runs atomic `make verify` (consolidated check).
- **CD Trigger (Draft/Version)**: `Release Please` is triggered via `workflow_run` after `Project Verification` succeeds.
- **CD Trigger (Distribution)**: `GoReleaser` is triggered **ONLY** by the **Git Tag** (v*) generated by Release Please.
- **Zero Redundancy**: Distribution workflows **MUST NOT** re-run verification jobs; they must trust the existing `main` verification results.
- **Automated Rollback**: Release workflows MUST include cleanup logic (e.g., deleting partial releases/tags) if the distribution fails.

### 6.3 Unified Entry Point (Makefile)

All CI workflows **MUST** invoke logic through `Makefile` targets rather than direct script calls. This ensures:

- **Local-CI Parity**: Developers can run `make verify` locally to get the exact same result as the CI.
- **Health Checks**: Every workflow initialization MUST include `make check-env` to validate the runner environment before execution.

## 7. CI Security & Supply Chain

- **Strict Action Version Pinning (MANDATORY)**: All GitHub Actions references MUST use **exact version tags** (e.g., `v4.2.2`). Never use mutable major version tags (`@v4`, `@v2`) — they can be silently overwritten by the action author, breaking reproducibility and enabling supply-chain attacks. Always use the **latest available exact version**.

  ```yaml
  # ❌ WRONG — mutable major tag, non-deterministic
  - uses: actions/checkout@v4
  - uses: actions/setup-node@v4
  - uses: pnpm/action-setup@v4

  # ✅ CORRECT — exact version, auditable, reproducible
  - uses: actions/checkout@v6.0.2
  - uses: actions/setup-node@v6.3.0
  - uses: pnpm/action-setup@v4.2.0
  ```

  **Gold standard**: Pin to the **exact version tag** (e.g., `v6.0.2`). This is the required standard for all workflows in this project — auditable, reproducible, and sufficient for supply-chain safety when combined with Dependabot automatic updates.

  ```yaml
  # ✅ GOLD STANDARD — exact version tag, auditable and reproducible
  - uses: actions/checkout@v6.0.2
  - uses: actions/setup-node@v6.3.0
  - uses: pnpm/action-setup@v4.4.0
  ```

  Use `dependabot` (with `version-updates` for GitHub Actions) to automatically track and update pinned versions.

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
