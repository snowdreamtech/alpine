# 03 · Architecture

> Structural, organizational, and design standards across all projects.

::: tip Source
This page summarizes [`.agent/rules/03-architecture.md`](https://github.com/snowdreamtech/template/blob/main/.agent/rules/03-architecture.md).
:::

## Cross-Platform Design

- Never hard-code OS-specific paths. Use relative paths or runtime detection
- All shell scripts MUST work on bash ≥ 3.2 (macOS default) and POSIX sh
- Use `#!/usr/bin/env bash` shebangs, not `/bin/bash`
- Test on Linux and macOS in CI matrix builds

## Project Structure

```
.
├── .agent/              # AI IDE rules and workflows (Single Source of Truth)
│   ├── rules/           # All development standards
│   └── workflows/       # SpecKit and custom workflows
├── .devcontainer/       # VS Code DevContainer configuration
├── .github/             # GitHub Actions, issue templates, Dependabot
├── docs/                # VitePress documentation site
├── scripts/             # Shell scripts for setup and automation
├── Makefile             # Developer-facing commands
└── README.md            # Project entry point
```

## Layered Architecture

Follow a clear separation of concerns. For any non-trivial application:

```
Presentation Layer    → UI, API handlers, CLI commands
Application Layer     → Use cases, orchestration, DTOs
Domain Layer          → Business entities, domain logic, interfaces
Infrastructure Layer  → Databases, external APIs, file system
```

**Rules:**

- Business logic MUST NOT live in the presentation or infrastructure layer
- Infrastructure implementations depend on domain interfaces (Dependency Inversion)
- No circular dependencies between layers

## Dependency Direction

```
Presentation → Application → Domain ← Infrastructure
```

- Domain has zero external dependencies
- Infrastructure implements domain interfaces
- Application orchestrates domain logic

## API Design

- RESTful APIs: use nouns for resources (`/users`, `/orders`), HTTP verbs for actions
- Version APIs from day one: `/api/v1/...`
- Return consistent error responses:

```json
{
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "User with id '123' does not exist",
    "requestId": "req_abc123"
  }
}
```

## Configuration Management

- All configuration via environment variables (12-factor app)
- Never hard-code environment-specific values (URLs, credentials, ports)
- Provide a `.env.example` with all required variables documented
- Validate required config at startup — fail fast with a clear error message
