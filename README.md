# Snowdream Tech AI IDE Template

[![GitHub Actions Lint](https://github.com/snowdreamtech/template/actions/workflows/lint.yml/badge.svg)](https://github.com/snowdreamtech/template/actions/workflows/lint.yml)
[![GitHub Actions Verify](https://github.com/snowdreamtech/template/actions/workflows/verify.yml/badge.svg)](https://github.com/snowdreamtech/template/actions/workflows/verify.yml)
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
2. **Bootstrap and Setup Environment**:
   Run the cross-platform setup script to configure your local environment:
   - **macOS / Linux**: `sh scripts/setup.sh`
   - **Windows (PowerShell)**: `.\scripts\setup.ps1`
   - **Windows (CMD)**: `scripts\setup.bat`
3. **Project Hydration**:
   Re-brand the template for your new project:

   ```bash
   make init
   ```

4. **Initialize AI Workflows**:
   Trigger the initialization by typing `@[/snowdreamtech.init]` in your AI agent chat. This will configure `corepack`, install local linters/formatters, and activate `pre-commit` hooks.
5. **Read the Rules**:
   Before coding, ensure both you and your AI assistant has read the core principles at `.agent/rules/01-general.md`.

## 🛠️ Full Automation Matrix

This template features a professional-grade script library (18 tool suites) that ensures **Single Source of Truth (SSoT)** across macOS, Linux, and Windows. All tools are natively accessible via `make` or `pnpm/npm`.

| Suite        | Goal                       | Commands                                |
| :----------- | :------------------------- | :-------------------------------------- |
| **Core**     | Onboarding & Project Setup | `init`, `setup`, `check-env`            |
| **Quality**  | Reliability & Standards    | `test`, `lint`, `format`, `verify`      |
| **Security** | Auditing & Compliance      | `audit`, `env`                          |
| **Ops**      | Building & Releasing       | `build`, `release`, `archive-changelog` |
| **Maint**    | Tooling & Cleanup          | `update`, `cleanup`                     |
| **DX**       | Developer Productivity     | `install`, `docs`, `commit`, `bench`    |

## 🛠️ SpecKit Collaboration Workflows

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

#### Local Development (本地开发)

1. Open the project in VS Code.
2. Ensure Docker Desktop is running.
3. If you have the "Dev Containers" extension installed, you will be prompted to "Reopen in Container".
4. Alternatively, use the Command Palette (`F1`) and select `Dev Containers: Reopen in Container`.

#### Remote Development (远程 SSH 开发)

1. Connect to your remote server via `Remote - SSH` extension.
2. Open this project folder on the remote server.
3. Use the Command Palette (`F1`) and select `Dev Containers: Reopen in Container`. VS Code will build and run the container on the **remote server's Docker engine**.

### Configuration

#### Switch to Docker Compose (切换混合模式)

To enable **PostgreSQL** and **Redis**:

1. Open `.devcontainer/devcontainer.json`.
2. Follow the internal comments to swap the `build` section with the `dockerComposeFile` section.
3. Rebuild the container.

#### Custom Base Image (自定义镜像)

If you need to use a private or enterprise image:

1. Modify the `FROM` instruction in `.devcontainer/Dockerfile`.
2. Ensure your image has a `vscode` user or adjust the `remoteUser` setting in `devcontainer.json`.

## 📄 License

This project is licensed under the **MIT License**.
Copyright (c) 2026-present [SnowdreamTech Inc.](https://github.com/snowdreamtech)
See the [LICENSE](./LICENSE) file for the full license text.
