# Bugfix Requirements Document

## Introduction

在 CI 工作流中，通过 `run_mise install` 动态安装的工具（如 Gitleaks、Zizmor、OSV-Scanner 等）在同一个 shell step 内无法被后续命令找到。根本原因是 `run_mise()` 函数将工具路径写入 `$GITHUB_PATH` 文件以实现跨 step 持久化，但 GitHub Actions 的 `GITHUB_PATH` 机制只在不同 step 之间生效，不会自动更新当前 shell 的 `$PATH` 环境变量。这导致在同一个 step 中，`make setup && make install && make check-env` 的执行序列中，`check-env.sh` 无法检测到刚刚安装的工具。

此 bug 影响所有通过 mise 动态安装的 20+ 个工具，包括安全扫描工具（Gitleaks、Zizmor、OSV-Scanner）、代码质量工具（Shellcheck、Shfmt、Actionlint）等，严重影响 CI 流水线的可靠性。

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN `run_mise install <tool>` 在 CI 环境的同一个 shell step 中被调用后，立即执行 `check-env.sh` THEN 系统报告工具未找到（例如 "❌ Zizmor: Not found"），即使工具已成功安装

1.2 WHEN `run_mise install` 将工具路径写入 `$GITHUB_PATH` 文件后，在同一个 shell 会话中调用 `resolve_bin <tool>` THEN 系统无法找到可执行文件，因为当前 shell 的 `$PATH` 变量未包含新安装工具的路径

1.3 WHEN CI 工作流在单个 step 中顺序执行 `make setup && make install && make check-env` THEN 系统在 `check-env` 阶段失败，因为 `$GITHUB_PATH` 的更新不会影响当前正在运行的 shell 进程

1.4 WHEN 工具通过 mise 安装到 `~/.local/share/mise/installs/<tool>/<version>/bin` 目录 THEN 该路径仅被写入 `$GITHUB_PATH` 文件，但不会被添加到当前 shell 的 `$PATH` 环境变量中

### Expected Behavior (Correct)

2.1 WHEN `run_mise install <tool>` 在 CI 环境中被调用后 THEN 系统应立即将工具路径添加到当前 shell 的 `$PATH` 环境变量，使工具在同一 shell 会话中可用

2.2 WHEN `run_mise install` 成功安装工具后 THEN 系统应同时执行两个操作：(a) 将路径写入 `$GITHUB_PATH` 文件（用于后续 step），(b) 将路径添加到当前 shell 的 `export PATH`（用于当前 step）

2.3 WHEN CI 工作流在单个 step 中顺序执行 `make setup && make install && make check-env` THEN 系统应在 `check-env` 阶段成功检测到所有已安装的工具（例如 "✅ Zizmor: v1.23.1 (Active)"）

2.4 WHEN 工具通过 mise 安装后，`resolve_bin <tool>` 被调用 THEN 系统应能够立即在当前 shell 的 `$PATH` 中找到可执行文件

2.5 WHEN 在 CI 环境中安装工具时 THEN 系统应确保路径更新的幂等性，避免在 `$PATH` 和 `$GITHUB_PATH` 中重复添加相同路径

### Unchanged Behavior (Regression Prevention)

3.1 WHEN `run_mise install` 在非 CI 环境（本地开发环境）中被调用 THEN 系统应继续正常工作，不依赖 `$GITHUB_PATH` 机制

3.2 WHEN 工具已经在 `$PATH` 中存在时，`run_mise install` 被调用 THEN 系统应继续跳过重复安装，保持性能优化

3.3 WHEN `run_mise install` 失败或超时时 THEN 系统应继续执行现有的重试和错误处理逻辑

3.4 WHEN mise shims 目录（`$_G_MISE_SHIMS_BASE`）已经在 `$PATH` 中时 THEN 系统应继续避免重复添加，保持幂等性

3.5 WHEN 工具路径已经在 `$GITHUB_PATH` 文件中时 THEN 系统应继续跳过重复写入，避免文件污染

3.6 WHEN 在不同的 GitHub Actions step 之间 THEN 系统应继续通过 `$GITHUB_PATH` 机制正确传递工具路径

3.7 WHEN `run_mise install` 安装需要后端管理器的工具（如 `cargo:*`、`go:*`、`npm:*`）时 THEN 系统应继续执行现有的依赖检查逻辑

3.8 WHEN 使用 Adaptive Lock Forgiveness (ALF) 机制处理 `go:` 前缀工具时 THEN 系统应继续正确调整 `MISE_LOCKED` 参数
