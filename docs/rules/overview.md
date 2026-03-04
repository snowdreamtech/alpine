# Rules Overview

The `.agent/rules/` directory is the **single source of truth** for all development standards in this repository. Every AI IDE (Cursor, Windsurf, Claude, Copilot, etc.) reads from the same rule files, ensuring consistent behavior across all AI coding assistants.

## Rule Files

| File                                       | Scope                                        |
| ------------------------------------------ | -------------------------------------------- |
| [01 · General](./01-general.md)               | Language, communication, core principles     |
| [02 · Coding Style](./02-coding-style.md)     | Commit messages, naming, formatting          |
| [03 · Architecture](./03-architecture.md)     | Project structure, cross-platform design     |
| [04 · Security](./04-security.md)             | Secrets, auth, input validation              |
| [05 · Dependencies](./05-dependencies.md)     | Version pinning, lock files, auditing        |
| [06 · CI & Testing](./06-ci-testing.md)       | Pipelines, quality gates, test strategy      |
| [07 · Git](./07-git.md)                       | Branch strategy, PR workflow, atomic commits |
| [08 · Dev Env](./08-dev-env.md)               | Local setup, DevContainer, tooling           |
| [09 · AI Interaction](./09-ai-interaction.md) | AI agent behavior and boundaries             |
| [10 · UI/UX](./10-ui-ux.md)                   | Frontend, accessibility, i18n                |
| [11 · Deployment](./11-deployment.md)         | Docker, IaC, release pipelines               |

## How Rules Work

Rules are loaded automatically by each AI IDE via their respective config files:

- **Cursor** → `.cursor/rules/` (symlinks to `.agent/rules/`)
- **Windsurf** → `.windsurfrules`
- **Claude / Gemini** → `CLAUDE.md` / `GEMINI.md` (redirect to `.agent/rules/`)
- **GitHub Copilot** → `.github/copilot-instructions.md`
- **Continue** → `.continue/config.json`

## Adding or Modifying Rules

1. Edit the relevant file in `.agent/rules/`
2. All AI IDEs will pick up the change automatically on next session
3. Commit with `docs(rules): <description>`

> **Single Source of Truth**: Never edit IDE-specific rule files directly. Always update `.agent/rules/` and let the symlinks/redirects propagate the change.
