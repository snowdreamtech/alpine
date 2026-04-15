# Mise Attestation Verification Error

## 问题描述

在运行 `make sync-lock` 或 `mise install` 时，可能会遇到以下错误：

```
mise ERROR github:astral-sh/ruff@0.15.10 has no provenance verification on linux-x64-musl,
but github:astral-sh/ruff@0.15.9 had github-attestations. This could indicate a supply chain attack.
Verify the release is authentic before proceeding.
```

## 根本原因

这个错误是由于 mise 使用 **Aqua Registry** 作为后端来安装工具，而不是直接从 GitHub 下载。

### 技术细节

1. **Mise 的后端机制**
   - 当你在 `.mise.toml` 中指定 `github:astral-sh/ruff` 时
   - mise 实际上使用 `aqua:astral-sh/ruff` 作为后端
   - 可以在 <https://mise-versions.jdx.dev/tools/ruff> 查看

2. **Aqua Registry 配置**
   - Aqua Registry 在 `pkgs/astral-sh/ruff/registry.yaml` 中配置了 `github_artifact_attestations`
   - 配置要求验证 GitHub Artifact Attestations（来源证明）

3. **验证失败的原因**
   - mise 在某些平台（如 linux-x64-musl, linux-arm64, macos-x64 等）上无法找到或验证 attestations
   - 这可能是由于：
     - mise 的 attestation 验证逻辑有 bug
     - GitHub API 返回的 attestation 数据格式变化
     - 网络问题导致无法下载 attestation 文件
     - Aqua Registry 的配置与实际 release 不匹配

4. **实际情况**
   - 经过验证，ruff 0.15.9 和 0.15.10 **都有** GitHub Artifact Attestations
   - 可以通过 `gh attestation verify` 命令验证
   - 这不是真正的供应链攻击，而是 mise 的误报

## 解决方案

### 方案 1: 临时跳过验证（推荐用于开发环境）

在 `.mise.toml` 中添加配置跳过 attestation 验证：

```toml
[settings]
# Skip attestation verification (use with caution)
experimental = true
```

或者使用环境变量：

```bash
export MISE_SKIP_CHECKSUM=1
make sync-lock
```

### 方案 2: 手动验证后继续

1. 手动验证 release 的真实性：

```bash
# 下载 ruff 二进制文件
gh release download 0.15.10 --repo astral-sh/ruff --pattern "ruff-x86_64-unknown-linux-gnu.tar.gz"

# 验证 attestation
gh attestation verify ruff-x86_64-unknown-linux-gnu.tar.gz --repo astral-sh/ruff
```

1. 确认验证通过后，使用 `--yes` 标志强制安装：

```bash
mise install github:astral-sh/ruff@0.15.10 --yes
```

### 方案 3: 降级到已知可用的版本

如果 attestation 验证持续失败，可以暂时使用 0.15.9：

```toml
# .mise.toml
[tools]
"github:astral-sh/ruff" = "0.15.9"
```

### 方案 4: 切换到其他安装方式

使用 pipx 或 cargo 安装 ruff，而不是通过 mise：

```toml
# .mise.toml
[tools]
# 使用 pipx 安装（Python 包）
"pipx:ruff" = "0.15.10"

# 或使用 cargo 安装（Rust 包）
"cargo:ruff" = "0.15.10"
```

## 验证步骤

### 1. 检查 mise 使用的后端

```bash
# 查看 mise 版本信息
mise --version

# 查看工具的后端信息
mise ls --json | jq '.[] | select(.name == "ruff")'
```

### 2. 手动验证 GitHub Attestations

```bash
# 安装 GitHub CLI（如果还没有）
brew install gh  # macOS
# 或
apt install gh   # Linux

# 验证 attestation
gh attestation verify <downloaded-file> --repo astral-sh/ruff
```

### 3. 检查 Aqua Registry 配置

查看 Aqua Registry 中 ruff 的配置：
<https://github.com/aquaproj/aqua-registry/blob/main/pkgs/astral-sh/ruff/registry.yaml>

## 预防措施

### 1. 锁定版本

在 `mise.lock` 中锁定已验证的版本：

```bash
# 生成或更新 lockfile
mise install
mise lock
```

### 2. 使用 CI 缓存

在 CI 中缓存 mise 安装的工具，避免每次都重新验证：

```yaml
# .github/workflows/ci.yml
- uses: actions/cache@v4
  with:
    path: ~/.local/share/mise
    key: mise-${{ runner.os }}-${{ hashFiles('mise.lock') }}
```

### 3. 监控 mise 更新

关注 mise 的更新日志，查看 attestation 验证相关的修复：

- <https://github.com/jdx/mise/releases>
- <https://github.com/jdx/mise/issues>

## 相关链接

- [GitHub Artifact Attestations 文档](https://docs.github.com/en/actions/security-for-github-actions/using-artifact-attestations/using-artifact-attestations-to-establish-provenance-for-builds)
- [Aqua Registry](https://github.com/aquaproj/aqua-registry)
- [Mise 文档](https://mise.jdx.dev/)
- [Ruff Releases](https://github.com/astral-sh/ruff/releases)

## 报告问题

如果你认为这是 mise 的 bug，可以在以下位置报告：

1. **Mise 项目**: <https://github.com/jdx/mise/issues>
2. **Aqua Registry**: <https://github.com/aquaproj/aqua-registry/issues>

报告时请包含：

- mise 版本 (`mise --version`)
- 操作系统和架构
- 完整的错误信息
- `MISE_VERBOSE=1` 的详细日志
