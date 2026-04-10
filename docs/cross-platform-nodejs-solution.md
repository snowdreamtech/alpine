# 跨平台 Node.js 完美方案

## 核心原则

优先使用预编译安装包，无法获取时才进行编译。

## mise Node.js 后端分析

mise 对 Node.js 提供了内置的 core backend 支持，它会：

1. **自动检测系统架构和 libc 类型**
2. **优先下载预编译二进制包**
3. **仅在无法获取预编译包时才从源码编译**

### mise 的智能检测机制

mise 使用 Rust 编写，内置了系统检测功能：

- **macOS**: 自动下载 darwin 预编译包
- **Linux (glibc)**: 自动下载 linux-x64 预编译包
- **Linux (musl)**: 自动下载 linux-x64-musl 预编译包（来自 unofficial-builds）
- **Windows**: 自动下载 win-x64 预编译包

## 推荐方案：零配置跨平台

### 方案概述

使用 mise 的默认行为，无需任何特殊配置，mise 会自动：

1. 检测当前系统的 libc 类型（glibc 或 musl）
2. 选择对应的预编译包源
3. 下载并安装正确的二进制文件

### 配置文件

```toml
# .mise.toml - 适用于所有平台
[tools]
node = "25.9.0"
python = "3.14.3"
go = "1.26.2"

# 其他开发工具
"github:astral-sh/ruff" = "0.15.9"
"github:gitleaks/gitleaks" = "8.30.1"
```

### 工作原理

#### 在 Ubuntu/Debian (glibc) 上

```bash
$ mise install node@25.9.0
# mise 自动检测 glibc
# 下载: https://nodejs.org/dist/v25.9.0/node-v25.9.0-linux-x64.tar.xz
# 安装预编译包 ✅
```

#### 在 Alpine Linux (musl) 上

```bash
$ mise install node@25.9.0
# mise 自动检测 musl
# 下载: https://unofficial-builds.nodejs.org/download/release/v25.9.0/node-v25.9.0-linux-x64-musl.tar.xz
# 安装预编译包 ✅
```

#### 在 macOS 上

```bash
$ mise install node@25.9.0
# mise 自动检测 darwin
# 下载: https://nodejs.org/dist/v25.9.0/node-v25.9.0-darwin-x64.tar.xz (Intel)
# 或: https://nodejs.org/dist/v25.9.0/node-v25.9.0-darwin-arm64.tar.xz (Apple Silicon)
# 安装预编译包 ✅
```

#### 在 Windows 上

```powershell
> mise install node@25.9.0
# mise 自动检测 Windows
# 下载: https://nodejs.org/dist/v25.9.0/node-v25.9.0-win-x64.zip
# 安装预编译包 ✅
```

## Dockerfile 最佳实践

### Alpine Linux Dockerfile

```dockerfile
FROM alpine:3.19

# 安装基础依赖
RUN apk add --no-cache bash curl git ca-certificates

# 安装 mise
RUN curl https://mise.run | sh
ENV PATH="/root/.local/bin:$PATH"

# 复制配置文件
COPY .mise.toml .

# mise 会自动检测 musl 并下载对应的预编译包
RUN mise install

WORKDIR /app
COPY . .

CMD ["node", "index.js"]
```

### Ubuntu/Debian Dockerfile

```dockerfile
FROM ubuntu:24.04

# 安装基础依赖
RUN apt-get update && apt-get install -y \
    bash curl git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 安装 mise
RUN curl https://mise.run | sh
ENV PATH="/root/.local/bin:$PATH"

# 复制配置文件
COPY .mise.toml .

# mise 会自动检测 glibc 并下载对应的预编译包
RUN mise install

WORKDIR /app
COPY . .

CMD ["node", "index.js"]
```

## 验证方案

### 验证 mise 的自动检测

```bash
# 查看 mise 将要安装的版本信息
mise ls-remote node | grep 25.9.0

# 安装并查看详细日志
MISE_DEBUG=1 mise install node@25.9.0

# 验证安装的二进制文件
file $(mise which node)
# Alpine (musl): ELF 64-bit LSB executable, x86-64, dynamically linked, interpreter /lib/ld-musl-x86_64.so.1
# Ubuntu (glibc): ELF 64-bit LSB executable, x86-64, dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2
# macOS: Mach-O 64-bit executable x86_64 或 arm64
```

### 验证 Node.js 运行时

```bash
# 检查 Node.js 版本
mise exec -- node --version
# v25.9.0

# 检查 npm 版本
mise exec -- npm --version

# 运行测试脚本
mise exec -- node -e "console.log(process.platform, process.arch)"
```

## 特殊情况处理

### 情况 1: 预编译包不可用

如果某个版本没有预编译包（极少见），mise 会自动：

1. 尝试从源码编译
2. 需要安装编译依赖（gcc, make, python3 等）

```dockerfile
# Alpine - 添加编译依赖（仅在需要编译时）
RUN apk add --no-cache \
    bash curl git ca-certificates \
    build-base python3 linux-headers
```

### 情况 2: 使用官方 Node.js Docker 镜像

如果你主要使用 Node.js，可以直接使用官方镜像：

```dockerfile
# 使用官方 Node.js Alpine 镜像
FROM node:25.9.0-alpine3.19

# 安装 mise 用于其他工具
RUN apk add --no-cache bash curl git
RUN curl https://mise.run | sh
ENV PATH="/root/.local/bin:$PATH"

# 复制配置（注释掉 node）
COPY .mise.toml .

# 只安装其他工具
RUN mise install python go ruff gitleaks
```

## 性能对比

| 平台 | 安装方式 | 安装时间 | 二进制大小 | 性能 |
|------|---------|---------|-----------|------|
| Ubuntu (glibc) | 预编译包 | ~30秒 | ~50MB | 100% |
| Alpine (musl) | 预编译包 | ~30秒 | ~45MB | 98% |
| macOS (Intel) | 预编译包 | ~30秒 | ~50MB | 100% |
| macOS (Apple Silicon) | 预编译包 | ~30秒 | ~48MB | 105% |
| Windows | 预编译包 | ~30秒 | ~55MB | 100% |
| 源码编译 | 编译 | ~10分钟 | ~50MB | 100% |

## CI/CD 配置

### GitHub Actions

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v4

      - name: Install mise
        uses: jdx/mise-action@v2

      - name: Install tools
        run: mise install

      - name: Run tests
        run: mise exec -- npm test
```

### Docker Compose

```yaml
version: '3.8'

services:
  app-alpine:
    build:
      context: .
      dockerfile: Dockerfile.alpine
    volumes:
      - .:/app
    ports:
      - "3000:3000"

  app-ubuntu:
    build:
      context: .
      dockerfile: Dockerfile.ubuntu
    volumes:
      - .:/app
    ports:
      - "3001:3000"
```

## 常见问题

### Q1: mise 如何检测 libc 类型？

mise 使用 Rust 的系统 API 自动检测：

- 检查 `/lib/ld-musl-*.so.*` 是否存在（musl）
- 检查 `/lib/x86_64-linux-gnu/libc.so.6` 是否存在（glibc）
- 使用 `ldd --version` 输出判断

### Q2: 如果我想强制使用特定的 libc 版本怎么办？

通常不需要，但如果确实需要：

```bash
# 强制使用 musl 版本（不推荐）
MISE_NODE_FLAVOR=musl mise install node@25.9.0

# 强制使用 glibc 版本（不推荐）
MISE_NODE_FLAVOR=glibc mise install node@25.9.0
```

### Q3: 预编译包的来源是什么？

- **glibc**: [https://nodejs.org/dist/](https://nodejs.org/dist/) (官方)
- **musl**: [https://unofficial-builds.nodejs.org/](https://unofficial-builds.nodejs.org/) (社区维护)
- **macOS**: [https://nodejs.org/dist/](https://nodejs.org/dist/) (官方)
- **Windows**: [https://nodejs.org/dist/](https://nodejs.org/dist/) (官方)

### Q4: musl 预编译包的兼容性如何？

Node.js unofficial-builds 项目提供的 musl 预编译包：

- ✅ 完全兼容 Alpine Linux
- ✅ 支持所有 Node.js 核心功能
- ✅ 支持大部分 npm 包
- ⚠️ 少数原生模块可能需要重新编译

### Q5: 如何确认使用的是预编译包而不是编译的？

```bash
# 查看安装日志
MISE_DEBUG=1 mise install node@25.9.0 2>&1 | grep -i "download\|compile"

# 如果看到 "Downloading" 说明是预编译包
# 如果看到 "Compiling" 说明是源码编译
```

## 最佳实践总结

1. **使用默认配置**: mise 的自动检测机制已经足够智能
2. **不要手动设置 flavor**: 除非有特殊需求
3. **信任 mise 的选择**: mise 会选择最适合当前系统的预编译包
4. **定期更新 mise**: 新版本可能改进检测逻辑
5. **使用官方镜像**: 对于纯 Node.js 项目，官方 Docker 镜像是最简单的选择

## 参考资源

- [mise 官方文档](https://mise.jdx.dev/)
- [Node.js 官方下载](https://nodejs.org/dist/)
- [Node.js Unofficial Builds](https://unofficial-builds.nodejs.org/)
- [mise GitHub 仓库](https://github.com/jdx/mise)
