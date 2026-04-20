# Alpine

[![GitHub Actions Lint](https://github.com/snowdreamtech/alpine/actions/workflows/lint.yml/badge.svg)](https://github.com/snowdreamtech/alpine/actions/workflows/lint.yml)
[![GitHub Actions Verify](https://github.com/snowdreamtech/alpine/actions/workflows/verify.yml/badge.svg)](https://github.com/snowdreamtech/alpine/actions/workflows/verify.yml)
[![GitHub Release](https://img.shields.io/github/v/release/snowdreamtech/alpine?include_prereleases&sort=semver)](https://github.com/snowdreamtech/alpine/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![CodeSize](https://img.shields.io/github/languages/code-size/snowdreamtech/alpine)](https://github.com/snowdreamtech/alpine)
[![Dependabot Enabled](https://img.shields.io/badge/Dependabot-Enabled-brightgreen?logo=dependabot)](https://github.com/snowdreamtech/alpine/blob/main/.github/dependabot.yml)
![Docker Image Version](https://img.shields.io/docker/v/snowdreamtech/alpine)
![Docker Image Size](https://img.shields.io/docker/image-size/snowdreamtech/alpine/latest)
![Docker Pulls](https://img.shields.io/docker/pulls/snowdreamtech/alpine)
![Docker Stars](https://img.shields.io/docker/stars/snowdreamtech/alpine)

[English](README.md) | [简体中文](README_zh-CN.md)

Alpine 的 Docker 镜像。支持多平台架构：(amd64, arm32v6, arm32v7, arm64v8, i386, ppc64le, riscv64, s390x)

## 使用方法

你可以使用 docker-compose 或 docker cli 启动容器。

### Docker Cli

#### 简单模式 (CLI)

```bash
docker run -d \
  --name=alpine \
  -e TZ=Asia/Shanghai \
  --restart unless-stopped \
  snowdreamtech/alpine:latest
```

#### 进阶模式 (CLI)

```bash
docker run -d \
  --name=alpine \
  -e TZ=Asia/Shanghai \
  -v /path/to/data:/path/to/data \
  --restart unless-stopped \
  snowdreamtech/alpine:latest
```

### Docker Compose

#### 简单模式 (Compose)

```yaml
version: "3"

services:
  alpine:
    image: snowdreamtech/alpine:latest
    container_name: alpine
    environment:
      - TZ=Asia/Shanghai
    restart: unless-stopped
```

#### 进阶模式 (Compose)

```yaml
version: "3"

services:
  alpine:
    image: snowdreamtech/alpine:latest
    container_name: alpine
    environment:
      - TZ=Asia/Shanghai
    volumes:
      - /path/to/data:/path/to/data
    restart: unless-stopped
```

## 环境变量

此镜像提供了多个环境变量来自定义其行为。

| 变量                   | 默认值    | 描述                                            |
| :--------------------- | :-------- | :---------------------------------------------- |
| `PUID`                 | `0`       | 运行进程的用户 ID。                             |
| `PGID`                 | `0`       | 运行进程的组 ID。                               |
| `USER`                 | `root`    | 运行进程的用户名。                              |
| `WORKDIR`              | `/root`   | 工作目录。                                      |
| `UMASK`                | `022`     | 文件创建的 Umask。                              |
| `DEBUG`                | `false`   | 启用 Entrypoint 的调试日志。                    |
| `KEEPALIVE`            | `0`       | 设置为 `1` 以保持容器持续运行。                 |
| `TZ`                   | `UTC`     | 时区设置。                                      |
| `CAP_NET_BIND_SERVICE` | `0`       | 设置为 `1` 以授予绑定特权端口 (< 1024) 的权限。 |
| `LANG`                 | `C.UTF-8` | 系统的区域与语言设置。                          |

## 特性

### 用户映射与权限

你可以使用 `PUID` 和 `PGID` 将镜像内的用户映射到宿主机的用户 ID 和组 ID。这在挂载数据卷时避免权限问题非常有用。

```bash
docker run -d \
  -e PUID=1000 \
  -e PGID=1000 \
  snowdreamtech/alpine:latest
```

### Entrypoint 扩展 (`entrypoint.d`)

此镜像支持自定义初始化脚本的扩展机制。任何放置在 `/usr/local/bin/entrypoint.d/` 目录（或构建前项目中的 `entrypoint.d/` 文件夹）中的可执行脚本都将在容器启动时按字母顺序执行。

### 内置软件包

镜像预装了一系列精选的基础工具：

- **Shell**: `bash`, `zsh`
- **Editors**: `vim`, `nano`
- **Network**: `curl`, `wget`, `rsync`, `git`
- **Utils**: `sudo`, `ca-certificates`, `tzdata`

## 开发指南

```bash
docker buildx create --use --name build --node build --driver-opt network=host
docker buildx build -t snowdreamtech/alpine --platform=linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64,linux/ppc64le,linux/riscv64,linux/s390x . --push
```

### 项目自动化工具

本项目使用了 Snowdream Tech Alpine 基础镜像，提供专业级的自动化支持。

| 套件     | 目标         | 命令                                    |
| :------- | :----------- | :-------------------------------------- |
| **核心** | 项目初始化   | `init`, `setup`, `install`, `check-env` |
| **质量** | 可靠性与标准 | `test`, `lint`, `format`, `verify`      |
| **安全** | 审计与合规   | `audit`, `env`                          |
| **运维** | 构建与发布   | `build`, `release`, `archive-changelog` |
| **维护** | 工具与清理   | `update`, `cleanup`                     |
| **DX**   | 开发者效率   | `docs`, `commit`, `bench`               |

更多关于 AI 优先的工作流细节，请参考 [CONVENTIONS.md](CONVENTIONS.md)。

## 参考资料

1. [使用 buildx 构建多平台 Docker 镜像](https://icloudnative.io/posts/multiarch-docker-with-buildx/)
1. [如何使用 docker buildx 构建跨平台 Go 镜像](https://waynerv.com/posts/building-multi-architecture-images-with-docker-buildx/#buildx-%E7%9A%84%E8%B7%A8%E5%B9%B3%E5%8F%B0%E6%9E%84%E5%BB%BA%E7%AD%96%E7%95%A5)
1. [Building Multi-Arch Images for Arm and x86 with Docker Desktop](https://www.docker.com/blog/multi-arch-images/)
1. [How to Rapidly Build Multi-Architecture Images with Buildx](https://www.docker.com/blog/how-to-rapidly-build-multi-architecture-images-with-buildx/)
1. [Faster Multi-Platform Builds: Dockerfile Cross-Compilation Guide](https://www.docker.com/blog/faster-multi-platform-builds-dockerfile-cross-compilation-guide/)
1. [docker/buildx](https://github.com/docker/buildx)

---

Copyright (c) 2024-present [SnowdreamTech Inc.](https://github.com/snowdreamtech)
