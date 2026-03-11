# Snowdream Tech AI IDE 模板

[![GitHub Actions Lint](https://github.com/snowdreamtech/template/actions/workflows/lint.yml/badge.svg)](https://github.com/snowdreamtech/template/actions/workflows/lint.yml)
[![GitHub Actions Verify](https://github.com/snowdreamtech/template/actions/workflows/verify.yml/badge.svg)](https://github.com/snowdreamtech/template/actions/workflows/verify.yml)
[![GitHub Release](https://img.shields.io/github/v/release/snowdreamtech/template?include_prereleases&sort=semver)](https://github.com/snowdreamtech/template/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![CodeSize](https://img.shields.io/github/languages/code-size/snowdreamtech/template)](https://github.com/snowdreamtech/template)
[![Dependabot Enabled](https://img.shields.io/badge/Dependabot-Enabled-brightgreen?logo=dependabot)](https://github.com/snowdreamtech/template/blob/main/.github/dependabot.yml)

[English](README.md) | [简体中文](README_zh-CN.md)

一个企业级、为多 AI IDE 协作而设计的基石模板。本项目作为 AI Agent 规则、工作流和项目配置的**单一事实来源 (Single Source of Truth)**，支持超过 50 种不同的 AI 辅助 IDE，并提供海量的多语言支持。

## 🌟 特性

- **多 IDE 兼容性**：开箱即用支持 Cursor、Windsurf、GitHub Copilot、Cline、Roo Code、Trae、Gemini、Claude Code 等 50 多种 AI 编辑器。
- **统一规则系统**：在 `.agent/rules/` 中维护中心化规则定义。在此修改规则通过安全的软链接/重定向模式自动传播到所有支持的 IDE。
- **80+ 语言与框架规则**：预配置的高质量规则，涵盖从 Rust、Go、TypeScript、Python 到 Ansible、Kubernetes 和 API 设计等各个领域。
- **智能工作流 (SpecKit)**：标准化的 `.agent/workflows/`（命令），如 `speckit.plan`、`speckit.analyze` 和 `snowdreamtech.init`，在所有支持的环境中保持一致。
- **三重保证质量**：通过 Pre-commit 和 GitHub Actions 集成门禁检查，确保 100% 的代码纯净。
- **跨平台就绪**：在 macOS (Homebrew/MacPorts)、Linux 和 Windows 上无缝运行。

## 🏗️ 设计与架构

Snowdream Tech 模板的架构旨在解决“单体项目多重 AI IDE 协作产生的配置碎片化”问题，确保在所有支持的环境中，规则和工作流保持绝对一致。

```mermaid
graph TD
    A[开发者与智能体 (Agents)] -->|操作| IDE[Cursor / Windsurf / Copilot / 50+ 其它]
    IDE -->|通过重定向读取规则| R1[.vscode/]
    IDE -->|通过重定向读取规则| R2[.github/]
    IDE -->|通过重定向读取规则| R3[.cline/ .trae/ 等等]

    R1 -.->|SSoT 指针| CoreRules[.agent/rules/]
    R2 -.->|SSoT 指针| CoreRules
    R3 -.->|SSoT 指针| CoreRules

    CoreRules -->|管理与约束| Src[项目应用源码]
    CoreRules -->|管理与约束| Scripts[CI/CD 与统一自动化脚本]
```

### 设计原则

- **唯一事实来源 (SSoT)**: 所有 AI 行为准则、开发脚手架命令和 Git 生态钩子均集中在一处维护，彻底消灭各 IDE 之间的配置孤岛与冗余。
- **跨平台多态性 (Cross-Platform)**: 核心自动化流水线基于原生 POSIX Shell 编写，且强制为 Windows (PowerShell / Batch) 提供对等兼容的轻量级包装层。
- **三重质量护城河 (Triple Guarantee)**: 由 IDE 实时自动修复、Pre-commit 本地强制阻断、以及 CI/CD (GitHub Actions) 远端全量审计，三层联防共同构建 100% 代码纯净度防线。

## 📂 目录结构

```text
project-root/
├── .agent/              # 🤖 权威 AI 配置 (大脑)
│   ├── rules/           # 📏 统一 AI 行为规则 (80+ 套件, SSoT)
│   └── workflows/       # 🛠️ 统一命令与 AI 工作流 (SpecKit)
├── .agents/             # 🧩 共享命令源 (自动管理的软链接)
├── .gemini/             # ♊ Gemini 专用扩展与 CLI 配置
├── .github/             # 🐙 GitHub 集成与 Copilot 设置
├── .vscode/             # 💻 优化的 VS Code 配置
├── .cline/              # 🔗 IDE 特定重定向文件夹示例 (内置 50+)
├── .pre-commit-config.yaml # ⚓ Pre-commit 钩子定义
└── src/                 # 📦 您的实际应用源代码
```

## 🚀 快速开始

为确保 100% 纯净且标准化的环境，请按顺序执行以下步骤：

### 1. 项目初始化 (首次初始化)

1. **克隆模板**。
2. **设置基础运行时**：确保已安装 Node.js 和 Python。
3. **注入品牌信息**：将模板重命名为您的项目身份。

   ```bash
   make init
   ```

4. **安装系统工具**：安装安全和 Lint 二进制文件（gitleaks、trivy 等）。

   ```bash
   make setup
   ```

5. **安装依赖**：安装项目特定包并激活钩子。

   ```bash
   make install
   ```

6. **最终验证**：确认一切配置正确。

   ```bash
   make verify
   ```

### 2. Git 同步 (Git Synchronization)

> [!IMPORTANT]
> 本仓库会定期进行历史记录清理。如果您遇到“分支分叉”或“拒绝合并无关历史”的情况，请使用以下命令同步：

```bash
# 1. 获取最新历史记录
git fetch origin

# 2. 将本地分支重置为远程状态
# 警告：这会丢弃本地未提交的更改。请先执行 git stash！
git reset --hard origin/dev  # 或 origin/main
```

### 3. 日常开发工作流 (日常开发)

遵循以下循环以保持高质量开发：

1. **同步**：`make install`（确保依赖是最新的）
2. **编码**：实现功能或修复 Bug。
3. **格式化**：`make format`（自动修复样式问题）
4. **代码检查**：`make lint`（验证标准）
5. **测试**：`make test`（验证逻辑）
6. **审计**：`make audit`（安全检查，建议在 PR 前执行）
7. **提交**：`make commit`（规范化提交）

## 🛠️ 全自动化矩阵

本模板拥有专业级的脚本库（18 套工具），确保在 macOS、Linux 和 Windows 上实现 **单一事实来源 (SSoT)**。所有工具均可通过 `make` 或 `pnpm/npm` 原生访问。

| 套件                | 目标           | 命令                                    |
| :------------------ | :------------- | :-------------------------------------- |
| **核心 (Core)**     | 入职与项目设置 | `init`, `setup`, `install`, `check-env` |
| **质量 (Quality)**  | 可靠性与标准   | `test`, `lint`, `format`, `verify`      |
| **安全 (Security)** | 审计与合规     | `audit`, `env`                          |
| **运维 (Ops)**      | 构建与发布     | `build`, `release`, `archive-changelog` |
| **维护 (Maint)**    | 工具与清理     | `update`, `cleanup`                     |
| **DX**              | 开发者效率     | `docs`, `commit`, `bench`               |

### 发布治理 (Release Governance)

我们的发布流程强制执行严格的 **'v' 前缀标准** 用于 Git 标签（例如 `v1.2.3`），同时保持 Manifest 版本号为纯数字。默认情况下，`make release` 仅执行本地审计；使用 `--git-tag` 进行显式发布。

## 📐 AI 交互指南

本项目严格执行交互规则以防止“AI 幻觉”。通过设计，我们的 IDE 设置会在会话启动时引导 Agent 阅读 `.agent/rules/09-ai-interaction.md`。

> **语言说明**：虽然所有技术代码、提交和规则定义必须使用英文，但与 AI 的所有沟通以及面向用户的文档应默认为 **简体中文 (Simplified Chinese)**。

## 🤝 项目规则定义

要增强 AI 行为，**不要**直接修改单个 IDE 配置目录。相反：

1. 在 `.agent/rules/` 中添加或修改 Markdown 文件。
2. 现有的软链接拓扑将自动把您的新规则应用到所有 50+ 个 AI 环境中。

## 🐳 DevContainer

本项目提供预配置的 **DevContainer**，以获得一致的企业级开发体验。它支持两种模式：

- **单容器 (默认)**：轻量级环境，预装所有 20+ CI 工具和 40+ VS Code 扩展。
- **Docker Compose (可选)**：包含 **PostgreSQL** 和 **Redis** 等附加服务。

### 如何使用

#### 本地开发 (Local Development)

1. 在 VS Code 中打开项目。
2. 确保 Docker Desktop 正在运行。
3. 如果您安装了 "Dev Containers" 扩展，系统会提示您“在容器中重新打开”。
4. 或者，使用命令面板 (`F1`) 并选择 `Dev Containers: Reopen in Container`。

#### 远程开发 (Remote SSH 开发)

1. 通过 `Remote - SSH` 扩展连接到远程服务器。
2. 在远程服务器上打开此项目文件夹。
3. 使用命令面板 (`F1`) 并选择 `Dev Containers: Reopen in Container`。VS Code 将在**远程服务器的 Docker 引擎**上构建并运行容器。

### 配置

#### 切换混合模式 (Switch to Docker Compose)

要启用 **PostgreSQL** 和 **Redis**：

1. 打开 `.devcontainer/devcontainer.json`。
2. 按照内部注释将 `build` 部分替换为 `dockerComposeFile` 部分。
3. 重新构建容器。

#### 自定义基础镜像 (Custom Base Image)

如果您需要使用私有或企业镜像：

1. 修改 `.devcontainer/Dockerfile` 中的 `FROM` 指令。
2. 确保您的镜像有 `vscode` 用户或调整 `devcontainer.json` 中的 `remoteUser` 设置。

## 📄 许可证

本项目采用 **MIT 许可证** 授权。
版权所有 (c) 2026-现在 [SnowdreamTech Inc.](https://github.com/snowdreamtech)
详见 [LICENSE](./LICENSE) 文件。
