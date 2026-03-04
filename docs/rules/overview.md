# Rule System Overview

The rule system is the foundation of this template — it defines how AI assistants should think and act within your project.

## Architecture

```text
.agent/rules/               ← Single Source of Truth
├── Core Rules (01–11)      ← Always loaded
└── Language Rules          ← Loaded on demand
    ├── go.md
    ├── python.md
    ├── typescript.md
    ├── react.md
    └── 70+ more...
```

## Two-Phase Rule Loading

Every AI assistant that reads this template's rules follows a two-phase loading protocol:

### Phase 1: Core Rules (Mandatory)

All 11 core rules are read in numerical order at the start of every session:

| #   | File                   | Covers                                                                  |
| --- | ---------------------- | ----------------------------------------------------------------------- |
| 01  | `01-general.md`        | Language, communication, idempotency, cross-platform, network, security |
| 02  | `02-coding-style.md`   | Commit messages, code quality, error handling, naming                   |
| 03  | `03-architecture.md`   | Project structure, AI IDE integration, design principles                |
| 04  | `04-security.md`       | Credentials, access control, encryption, scanning                       |
| 05  | `05-dependencies.md`   | Locking, integrity, auditing, release process                           |
| 06  | `06-ci-testing.md`     | Test types, CI pipeline, quality gates                                  |
| 07  | `07-git.md`            | Atomic commits, branching, pull requests, code review                   |
| 08  | `08-dev-env.md`        | DevContainer, scripts, pre-commit hooks                                 |
| 09  | `09-ai-interaction.md` | Safety, code generation, communication, atomic commits                  |
| 10  | `10-ui-ux.md`          | Styling, accessibility, performance, i18n                               |
| 11  | `11-deployment.md`     | Containerization, secrets, IaC, observability                           |

### Phase 2: Language & Framework Rules (Dynamic)

The AI inspects the project's files (`go.mod`, `package.json`, `pyproject.toml`, etc.) and loads the relevant language-specific rules:

**Languages:** JavaScript, TypeScript, Python, Go, Rust, Java, Kotlin, C#, Swift, PHP, Ruby, Scala, Elixir, Lua, R, C, C++, Shell/Bash, HTML, CSS, SQL, GraphQL

**Frameworks:** React, Next.js, Vue, Nuxt, Angular, Svelte, Express, NestJS, FastAPI, Django, Flask, Spring, Gin, Echo, Fiber, Flutter, and 40+ more

**Infrastructure:** Docker, Kubernetes, Terraform, Ansible, GitHub Actions, PostgreSQL, MongoDB, Redis, Elasticsearch, and more

## Editing Rules

::: warning
**Never modify individual IDE configuration directories directly.** Always edit `.agent/rules/` only.
:::

To add or modify a rule:

1. Edit the relevant file in `.agent/rules/`
2. All 50+ AI IDE directories will automatically use the updated rule on the next session — they all point back to this directory.

## Key Rules Highlighted

### Atomic Commits (07-git.md)

Every commit must address a **single logical change**. When implementing multiple changes:

1. Implement one change completely
2. Commit it immediately
3. Proceed to the next

### AI Interaction Safety (09-ai-interaction.md)

- No blind refactoring — AI must not change code outside the requested scope
- Explicit confirmation required for destructive operations
- Atomic commits are non-negotiable when executing multiple tasks

### Cross-Platform Compatibility (01-general.md)

All scripts and configurations must work on **Linux**, **macOS**, and **Windows** without hardcoded paths.
