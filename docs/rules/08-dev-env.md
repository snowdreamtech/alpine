# 08 · Dev Environment

> Standards for environment consistency, DevContainer, local tooling, and debugging.

::: tip Source
This page summarizes [`.agent/rules/08-dev-env.md`](https://github.com/snowdreamtech/template/blob/main/.agent/rules/08-dev-env.md).
:::

## Environment Consistency

**The DevContainer is the canonical development environment.** All developers and CI pipelines run in identical, reproducible containers.

- Define the container in `.devcontainer/devcontainer.json`
- Pin the base image to an exact digest or version tag
- Install all required tools in the container — never rely on "it works on my machine"

## Quick Start

```bash
# Clone and open in DevContainer (VS Code)
git clone https://github.com/snowdreamtech/template.git
cd template
code .
# VS Code prompts: "Reopen in Container" → click it
```

Or with the Makefile:

```bash
make setup     # Install all local tools (for development outside DevContainer)
make help      # Show all available commands
```

## Tool Version Management

Pin ALL tool versions explicitly using one of:

| Tool     | Pin via                                      |
| -------- | -------------------------------------------- |
| Node.js  | `.nvmrc` or `engines.node` in `package.json` |
| Python   | `.python-version` (pyenv)                    |
| Go       | `go.mod` `go` directive                      |
| Ruby     | `.ruby-version`                              |
| Bun/pnpm | `.mise.toml` or `.tool-versions`             |
| Java/JDK | `JAVA_HOME` + `.tool-versions`               |

## Pre-commit Hooks

All pre-commit hooks are defined in `.pre-commit-config.yaml`. Install once with:

```bash
pre-commit install
pre-commit install --hook-type commit-msg
```

Hooks run automatically on every `git commit`. To run manually:

```bash
pre-commit run --all-files
```

## Local Debugging

- Use structured logging with log levels (`DEBUG`, `INFO`, `WARN`, `ERROR`)
- Enable race detector in Go: `go test -race ./...`
- Use `dlv` (Go) or `debugpy` (Python) for step-through debugging
- Never debug in production — always reproduce locally first

## VS Code Extensions

Recommended extensions are defined in `.vscode/extensions.json` and auto-suggested when the workspace opens. Key extensions:

- Error Lens — inline error highlighting
- GitLens — Git history and blame
- Language-specific extensions for your stack
