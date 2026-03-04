# 01 · General

> Core principles that govern how AI assistants interact with this codebase.

::: tip Source
This page summarizes [`.agent/rules/01-general.md`](https://github.com/snowdreamtech/template/blob/main/.agent/rules/01-general.md). Always refer to the source for the authoritative version.
:::

## Language & Communication

- All code, comments, commit messages, and documentation MUST be written in **English**
- AI responses to the developer may use the developer's preferred language
- Use clear, precise technical language — avoid ambiguity in variable names, function signatures, and API contracts

## Core Principles

- **Idempotency**: Every operation must be safe to run multiple times without side effects
- **Reproducibility**: Given the same inputs, builds and deployments must always produce identical outputs
- **Least Privilege**: Grant only the minimum permissions required for any operation — in code, CI, and infrastructure
- **Fail Fast**: Detect and surface errors as early as possible; prefer explicit failures over silent fallbacks

## Cross-Platform Compatibility

All scripts, configs, and code MUST work consistently on:

- **Linux** — Debian, RedHat, Alpine
- **macOS** — Intel and Apple Silicon
- **Windows** — PowerShell and WSL2

Never hard-code OS-specific paths (`/usr/local/bin`, `C:\Users\...`). Use environment variables, relative paths, or runtime detection instead.

## Network & Proxy

When downloading resources (especially from GitHub), always configure retry logic and use a configurable proxy prefix (`{{ github_proxy }}`):

```bash
# ✅ Correct — with retry and proxy
curl -fsSL --retry 3 "{{ github_proxy }}https://github.com/..." -o output

# ❌ Wrong — no retry, no proxy
curl "https://github.com/..." -o output
```

## Security Baseline

- Never log or print secrets, tokens, or passwords
- All configuration values with security implications must be explicitly defined (no defaults that silently pass)
- Treat any API key, credential, or private key as a secret — never commit to version control
