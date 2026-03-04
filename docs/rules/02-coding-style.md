# 02 · Coding Style

> Universal coding conventions for consistent, readable, and maintainable code across all languages.

::: tip Source
This page summarizes [`.agent/rules/02-coding-style.md`](https://github.com/snowdreamtech/template/blob/main/.agent/rules/02-coding-style.md).
:::

## Git Commit Messages

Follow the **Conventional Commits** specification. All commits are validated by `commitlint`.

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

| Type       | When to use                          |
| ---------- | ------------------------------------ |
| `feat`     | New feature                          |
| `fix`      | Bug fix                              |
| `docs`     | Documentation only                   |
| `style`    | Formatting, no logic change          |
| `refactor` | Code restructure, no behavior change |
| `test`     | Adding or fixing tests               |
| `chore`    | Build, tooling, dependency updates   |
| `ci`       | CI/CD configuration changes          |
| `perf`     | Performance improvements             |
| `revert`   | Revert a previous commit             |

### Rules

- Subject line: imperative mood, no period, ≤ 72 characters
- Body: explain _why_, not _what_ (the diff shows the what)
- Breaking changes: add `!` after type (`feat!:`) and a `BREAKING CHANGE:` footer

## Naming Conventions

| Language      | Variables / Functions | Types / Classes | Constants     |
| ------------- | --------------------- | --------------- | ------------- |
| Go            | `camelCase`           | `PascalCase`    | `UPPER_SNAKE` |
| Python        | `snake_case`          | `PascalCase`    | `UPPER_SNAKE` |
| JavaScript/TS | `camelCase`           | `PascalCase`    | `UPPER_SNAKE` |
| Rust          | `snake_case`          | `PascalCase`    | `UPPER_SNAKE` |
| Java/Kotlin   | `camelCase`           | `PascalCase`    | `UPPER_SNAKE` |

## Code Formatting

- Always use the language's official or most widely adopted formatter:
  - Go → `gofmt` / `goimports`
  - Python → `ruff format`
  - JavaScript/TypeScript → `prettier`
  - Rust → `rustfmt`
  - Java → `google-java-format`
- Format on save in the editor; enforce in CI with `--check` flag
- Maximum line length: **120 characters** (configurable per project)

## Comments

- Write comments to explain **why**, not what
- Keep comments up to date — stale comments are worse than no comments
- Use `// TODO(owner): description` for tracked follow-up work
- Use `// FIXME(owner): description` for known bugs to be fixed

## Atomic Commits

Every commit must represent a single, coherent change that:

1. Passes all tests independently
2. Has a clear purpose described in the commit message
3. Does not mix unrelated changes (formatting + feature = two commits)
