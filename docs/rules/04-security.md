# 04 · Security

> Security standards for secrets management, authentication, input validation, and supply-chain integrity.

::: tip Source
This page summarizes [`.agent/rules/04-security.md`](https://github.com/snowdreamtech/template/blob/main/.agent/rules/04-security.md).
:::

## Secrets Management

- **Never commit secrets** to version control — no API keys, passwords, tokens, or private keys
- Use environment variables for all secrets; provide a `.env.example` template
- Rotate any secret that has been accidentally committed, even briefly
- Use secret scanning tools (Gitleaks, `git-secrets`) as pre-commit hooks and in CI

```bash
# Pre-commit secret scan (already configured in this template)
gitleaks detect --source . --report-format json --exit-code 1
```

## Authentication & Authorization

- Use established libraries and protocols — never roll your own crypto or auth
- Prefer **OAuth 2.0 / OIDC** for user authentication
- Use **short-lived tokens** (access tokens ≤ 15 min) with refresh token rotation
- Implement **rate limiting** on all authentication endpoints
- Hash passwords with **bcrypt** (cost ≥ 12), **Argon2id**, or **scrypt** — never MD5/SHA for passwords

## Input Validation

- Validate and sanitize ALL external input at the system boundary (API, CLI, forms)
- Use an allowlist approach: define what is valid, reject everything else
- Prevent injection attacks:
  - SQL: use parameterized queries / prepared statements
  - HTML: use context-aware escaping
  - Shell: avoid `exec(userInput)` — use safe APIs with argument arrays

## Dependency Security

- Run dependency audits in CI:
  - npm: `npm audit --audit-level=high`
  - Python: `pip-audit` or `safety check`
  - Go: `govulncheck ./...`
  - Rust: `cargo audit`
- Pin all dependencies to exact versions (see [05 · Dependencies](./05-dependencies))
- Configure Dependabot for automated security update PRs

## CI/CD Security

- Pin GitHub Actions to exact version tags or commit SHAs
- Use OIDC for cloud credentials — avoid long-lived static secrets in CI
- Apply least-privilege permissions to every workflow:

```yaml
permissions:
  contents: read
  # only add what is strictly needed
```

## OWASP Top 10

Always consider the current [OWASP Top 10](https://owasp.org/www-project-top-ten/) when designing features:

1. Broken Access Control
2. Cryptographic Failures
3. Injection
4. Insecure Design
5. Security Misconfiguration
6. Vulnerable and Outdated Components
7. Identification and Authentication Failures
8. Software and Data Integrity Failures
9. Security Logging and Monitoring Failures
10. Server-Side Request Forgery (SSRF)
