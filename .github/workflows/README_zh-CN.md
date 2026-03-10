# GitHub Actions 工作流指南

[English](file:///Users/snowdream/Workspace/snowdreamtech/template/.github/workflows/README.md) | [简体中文](file:///Users/snowdream/Workspace/snowdreamtech/template/.github/workflows/README_zh-CN.md)

本目录包含了 Snowdream Tech 项目的自动化 CI/CD 流水线和仓库维护任务。

## 1. 设计与架构

CI/CD 系统遵循 **三重保证 (Triple Guarantee)** 质量机制：

1. **本地钩子 (Local Hooks)**：`pre-commit` 提供即时反馈。
2. **CI 流水线**：对每个拉取请求进行严格验证。
3. **持续交付 (CD)**：自动化的版本管理和部署。

### 核心原则

- **最小权限 (Least Privilege)**：所有工作流均以最小的 GITHUB_TOKEN 权限运行。
- **快速失败 (Fail Fast)**：严格的超时设置和并行执行确保快速反馈。
- **可追溯性 (Traceability)**：结构化的文件头和“Why”注释解释了每个设计决策。
- **幂等性 (Idempotency)**：所有验证步骤均设计为可重复且安全的。

## 2. 使用指南

大多数工作流是全自动执行的。您也可以通过 GitHub 仓库的 **Actions** 选项卡使用 `workflow_dispatch` 手动触发它们。

### 主要工作流

| 工作流               | 职责               | 触发机制     |
| :------------------- | :----------------- | :----------- |
| `lint.yml`           | 代码质量与安全审计 | 推送/PR      |
| `test.yml`           | 多语言测试套件     | 推送/PR      |
| `verify.yml`         | 预检环境健康状况   | 推送/PR      |
| `release-please.yml` | 自动化版本发布     | 推送到主分支 |
| `pages.yml`          | 文档网站部署       | 文档变更     |

## 3. 运维指南

### 常见问题排除

- **权限不足 (Permission Denied)**：请检查工作流文件头部的 `permissions` 代码块。
- **Action 版本锁定**：确保 Action 使用 `x.y.z` 标签以保证稳定性。
- **超时 (Timeout)**：某些矩阵测试（如 Go/Python）可能需要增加 `timeout-minutes`。

## 4. 安全考虑

- **密钥处理 (Secret Handling)**：严禁在日志中输出密钥。始终在 `run:` 步骤中通过环境变量传递它们。
- **供应链安全**：对所有外部 Action 使用稳定的语义化版本标签。
- **OIDC**：用于云端集成，避免使用长期有效的静态凭据。

## 5. 开发指南

要添加新的工作流：

1. 在此目录下创建一个 `.yml` 文件。
2. 遵循 **World Class AI 文档规范** 的文件头模板。
3. 强制使用 `shell: sh` 以确保跨平台兼容性。
4. 在提交前，请在本地运行 `make verify` 和 `actionlint` 进行验证。
