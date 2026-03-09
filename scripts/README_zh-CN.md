# 自动化脚本工具箱

> [!NOTE]
> 此目录包含了项目自动化基础设施的实现。它遵循 **Single Source of Truth (SSoT)** 模式，核心逻辑位于 POSIX shell 脚本 (`.sh`) 中，并为 Windows 兼容性提供了包装器 (`.ps1`, `.bat`)。

## 1. 设计与架构

### 概览

该组件提供了一套跨平台的脚本，用于管理开发生命周期，包括环境设置、依赖安装、代码检查、测试和部署。

- **可移植性**: 使用 POSIX 兼容的 shell 编写，确保在 Linux、macOS 和 CI 环境中保持一致。
- **健壮性**: 包含安全守卫、原子操作和标准化的错误处理。
- **Windows 优化**: 从 CMD 和 PowerShell 完全委托给核心逻辑。

### 设计原则

- **SSoT (单一事实来源)**: 逻辑绝不会在 `.sh` 和 `.ps1` 之间重复。
- **幂等性**: 脚本可以安全地多次运行。
- **快速失败**: 出错时立即退出并提供明确的诊断信息。

## 2. 使用指南

### 前置条件

- **POSIX Shell** (Linux/macOS 标准配置；Windows 上建议使用 Git Bash 或 WSL)
- **PowerShell 5.1+** (用于 Windows 包装器)
- **Make** (可选，提供便捷的入口点)

### 快速开始

```bash
# 设置开发环境
sh scripts/setup.sh

# 验证环境健康状况
sh scripts/verify.sh
```

### 脚本参考

| 脚本                   | 用途           | 关键模块                   |
| :--------------------- | :------------- | :------------------------- |
| `setup.sh`             | 安装系统级工具 | node, python, go, rust 等  |
| `install.sh`           | 安装项目依赖   | pnpm, pip, pre-commit      |
| `check-env.sh`         | 验证工具版本   | 运行时、质量工具           |
| `verify.sh`            | 完整项目验证   | 环境、测试、代码检查、审计 |
| `update.sh`            | 更新所有工具链 | 管理器、钩子、依赖         |
| `init-project.sh`      | 修改模板品牌   | 占位符替换、git 初始化     |
| `archive-changelog.sh` | 归档旧版本     | 主版本更迭轮转             |

## 3. 运维指南

### 故障排除

- **权限不足**: 运行 `chmod +x scripts/*.sh`。
- **Windows 脚本执行策略**: 如果 `.ps1` 失败，运行 `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`。
- **被杀掉 (Exit 137)**: 通常表示二进制文件由于下载中断而损坏。运行 `rm .venv/bin/<tool>` 并重新运行 setup。

## 4. 安全考虑

- **无需 Sudo**: 大多数脚本将工具安装到项目本地的 `.venv/bin` 或用户本地目录。
- **校验逻辑**: 安装函数会验证二进制文件的存在和基本功能。
- **Gitleaks 集成**: `audit.sh` 和钩子确保不会提交任何敏感信息（密钥等）。

## 5. 开发指南

### 添加新脚本

1. 在 `scripts/my-script.sh` 中创建 POSIX 逻辑。
2. 引入 `scripts/lib/common.sh`。
3. 使用 `guard_project_root` 和 `parse_common_args`。
4. 按照 `.agent/rules/shell.md` 中的委托模板创建 `.ps1` 和 `.bat` 包装器。

### 库函数使用

`scripts/lib/common.sh` 提供：

- `log_info`, `log_success`, `log_warn`, `log_error`: 彩色日志。
- `download_url`: 健壮的带重试下载。
- `atomic_swap`: 安全的文件替换。
- `check_update_cooldown`: 为重型任务提供 24 小时频率限制。
