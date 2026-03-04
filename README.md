# Snowdream Tech AI IDE Template

[![GitHub Actions Lint](https://github.com/snowdreamtech/template/actions/workflows/lint.yml/badge.svg)](https://github.com/snowdreamtech/template/actions/workflows/lint.yml)
[![GitHub Release](https://img.shields.io/github/v/release/snowdreamtech/template?include_prereleases&sort=semver)](https://github.com/snowdreamtech/template/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![CodeSize](https://img.shields.io/github/languages/code-size/snowdreamtech/template)](https://github.com/snowdreamtech/template)
[![Dependabot Enabled](https://img.shields.io/badge/Dependabot-Enabled-brightgreen?logo=dependabot)](https://github.com/snowdreamtech/template/blob/main/.github/dependabot.yml)

An enterprise-grade, foundational template designed for multi-AI IDE collaboration. This repository serves as a **Single Source of Truth** for AI agent rules, workflows, and project configurations, supporting over 50 different AI-assisted IDEs with massive multi-language support.

## 🌟 Features

- **Multi-IDE Compatibility**: Out-of-the-box support for Cursor, Windsurf, GitHub Copilot, Cline, Roo Code, Trae, Gemini, Claude Code, and 50+ other AI editors.
- **Unified Rule System**: Centralized rule definitions in `.agent/rules/`. Modifying a rule here propagates to all supported IDEs via safe symlink/redirect patterns.
- **80+ Language & Framework Rules**: Pre-configured, high-quality rules for everything from Rust, Go, TypeScript, and Python to Ansible, Kubernetes, and API Design.
- **Intelligent Workflows (SpecKit)**: Standardized `.agent/workflows/` (commands) such as `speckit.plan`, `speckit.analyze`, and `snowdreamtech.init` available uniformly across supported environments.
- **Triple Guarantee Quality**: Integrated gated checks via Pre-commit and GitHub Actions to ensure 100% code purity.
- **Cross-Platform Ready**: Seamless operation across macOS (Homebrew/MacPorts), Linux, and Windows.

## 📂 Directory Structure

```text
project-root/
├── .agent/              # 🤖 Canonical AI configuration (The Brain)
│   ├── rules/           # 📏 Unified AI behavioral rules (80+ sets, SSoT)
│   └── workflows/       # 🛠️ Unified commands & AI workflows (SpecKit)
├── .agents/             # 🧩 Shared command sources (Auto-managed symlinks)
├── .gemini/             # ♊ Gemini-specific extensions and CLI configs
├── .github/             # 🐙 GitHub integration & Copilot settings
├── .vscode/             # 💻 Optimized VS Code configurations
├── .cline/              # 🔗 Example of IDE-specific redirect folder (50+ included)
├── .pre-commit-config.yaml # ⚓ Pre-commit hook definitions
└── src/                 # 📦 Your actual application source code
```

## 🚀 Getting Started

1. **Clone the template**.
2. **Initialize the Environment**:
   Trigger the initialization workflow by typing `@[/snowdreamtech.init]` in your AI agent chat. This will:
   - Install linguistically specific linters/formatters (e.g., `golangci-lint`, `checkmake`, `sqlfluff`, `ktlint`, `kube-linter`, `tflint`).
   - Configure platform-specific binary tools (e.g., MacPorts/Homebrew/Scoop/Winget/APT).
   - Activate `pre-commit` hooks for lightning-fast localized Shift-Left quality gates.
3. **Read the Rules**:
   Before coding, ensure both you and your AI assistant has read the core principles at `.agent/rules/01-general.md`.

## 🛠️ SpecKit Collaboration Workflows

This template includes the **SpecKit** workflow suite to manage the full feature lifecycle:

| Command              | Purpose                                                        |
| :------------------- | :------------------------------------------------------------- |
| `/speckit.specify`   | Create or update feature specification from natural language.  |
| `/speckit.plan`      | Execute implementation planning and generate design artifacts. |
| `/speckit.tasks`     | Generate actionable, dependency-ordered `tasks.md`.            |
| `/speckit.implement` | Execute the implementation plan task by task.                  |
| `/speckit.analyze`   | Perform cross-artifact consistency and quality analysis.       |

## 📐 AI Interaction Guidelines

This repository strictly enforces interaction rules to prevent "AI hallucinations". By design, our IDE settings redirect the agent to read `.agent/rules/09-ai-interaction.md` upon session startup.

> **Language Notice:** While all technical code, commits, and rule definitions must be in English, all communication with the AI and user-facing documentation should default to **Simplified Chinese (简体中文)**.

## 🤝 Project Rules Definition

To augment AI behavior, **do not** modify individual IDE configuration directories directly. Instead:

1. Add or modify markdown files inside `.agent/rules/`.
2. The existing symlink topology will automatically apply your new rules to all 50+ AI environments.

## 🐳 DevContainer

This project provides a pre-configured **DevContainer** for a consistent, enterprise-grade development experience. It supports two modes:

- **Single Container (Default)**: Lightweight environment with all 20+ CI tools and 40+ VS Code extensions pre-installed.
- **Docker Compose (Optional)**: Includes additional services like **PostgreSQL** and **Redis**.

### How to use

1. Open the project in VS Code.
2. If you have the "Dev Containers" extension installed, you will be prompted to "Reopen in Container".
3. Alternatively, use the Command Palette (`F1`) and select `Dev Containers: Reopen in Container`.

### Configuration

To switch to **Docker Compose** mode:

1. Open `.devcontainer/devcontainer.json`.
2. Follow the comments to swap the `build` section with the `dockerComposeFile` section.
3. Rebuild the container.

## 📄 License

This project is licensed under the **MIT License**.
Copyright (c) 2026-present [SnowdreamTech Inc.](https://github.com/snowdreamtech)
See the [LICENSE](./LICENSE) file for the full license text.
