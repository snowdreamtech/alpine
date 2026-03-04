# 06 · CI & Testing

> Test scope, quality thresholds, CI pipeline requirements, and gating strategy.

::: tip Source
This page summarizes [`.agent/rules/06-ci-testing.md`](https://github.com/snowdreamtech/template/blob/main/.agent/rules/06-ci-testing.md).
:::

## Test Types

All projects must include:

| Type                  | Goal                             | Required                |
| --------------------- | -------------------------------- | ----------------------- |
| **Unit tests**        | Correct logic in isolation       | ✅ Always               |
| **Integration tests** | Component interactions           | ✅ Always               |
| **E2E tests**         | Full user flows                  | ✅ User-facing apps     |
| **Contract tests**    | Service-to-service API contracts | ✅ Microservices        |
| **Benchmark tests**   | Performance regression detection | For perf-critical paths |

## Coverage Targets

| Scope                | Minimum             |
| -------------------- | ------------------- |
| Core business logic  | ≥ 80% line & branch |
| Auth / Payment paths | ≥ 95%               |
| UI components        | ≥ 70%               |

## CI Pipeline Requirements

Every PR must pass CI before merging. The pipeline is **hermetically sealed**:

- All dependencies pinned (lock files committed)
- Deterministic cache keys using lock file hashes
- No network calls during tests

### Pipeline Stages

```
Stage 1 (< 3 min):   lint · format · typecheck · unit tests
Stage 2 (< 10 min):  integration tests · contract tests
Stage 3 (parallel):  E2E · security scans · benchmarks
```

## GitHub Actions Version Pinning

All GitHub Actions MUST use **exact version tags** — never mutable major tags:

```yaml
# ❌ WRONG — mutable, non-deterministic
- uses: actions/checkout@v4

# ✅ CORRECT — exact, auditable
- uses: actions/checkout@v6.0.2
```

**Gold standard**: Pin to the immutable commit SHA:

```yaml
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v6.0.2
```

Use Dependabot or Renovate (with `pinDigests: true`) to automate version tracking.

## Quality Gates

These block merging:

- ❌ Any linter error
- ❌ Any test failure
- ❌ Coverage below threshold
- ❌ Security finding of HIGH or CRITICAL severity
- ❌ Build failure or type error

## Flaky Tests

A test is flaky if it fails intermittently without code changes:

- **Quarantine within 24 hours** using `@skip` with issue reference
- **Resolve within 2 weeks** — fix the root cause
- Never use retry-on-failure as a long-term solution
