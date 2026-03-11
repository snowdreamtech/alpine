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

Docker Image packaging for Alpine. (amd64, arm32v6, arm32v7, arm64v8, i386, ppc64le,riscv64, s390x)

## Usage

To help you get started creating a container from this image you can either use docker-compose or the docker cli.

### Docker Cli

#### CLI - Simple

```bash
docker run -d \
  --name=alpine \
  -e TZ=Asia/Shanghai \
  --restart unless-stopped \
  snowdreamtech/alpine:latest
```

#### CLI - Advance

```bash
docker run -d \
  --name=alpine \
  -e TZ=Asia/Shanghai \
  -v /path/to/data:/path/to/data \
  --restart unless-stopped \
  snowdreamtech/alpine:latest
```

### Docker Compose

#### Compose - Simple

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

#### Compose - Advance

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

## Environment Variables

This image provides several environment variables to customize its behavior.

| Variable               | Default   | Description                                                          |
| :--------------------- | :-------- | :------------------------------------------------------------------- |
| `PUID`                 | `0`       | User ID for the running process.                                     |
| `PGID`                 | `0`       | Group ID for the running process.                                    |
| `USER`                 | `root`    | Username for the running process.                                    |
| `WORKDIR`              | `/root`   | Working directory.                                                   |
| `UMASK`                | `022`     | Umask for file creation.                                             |
| `DEBUG`                | `false`   | Enable debug logging for the entrypoint.                             |
| `KEEPALIVE`            | `0`       | Set to `1` to keep the container running indefinitely.               |
| `TZ`                   | `UTC`     | Timezone setting.                                                    |
| `CAP_NET_BIND_SERVICE` | `0`       | Set to `1` to grant permission to bind to privileged ports (< 1024). |
| `LANG`                 | `C.UTF-8` | System locale and language setting.                                  |

## Features

### User Mapping & Permissions

You can map the internal user to your host user's ID and Group ID using `PUID` and `PGID`. This is extremely useful for avoiding permission issues when using volumes.

```bash
docker run -d \
  -e PUID=1000 \
  -e PGID=1000 \
  snowdreamtech/alpine:latest
```

### Entrypoint Extension (`entrypoint.d`)

This image supports an extension mechanism for custom initialization scripts. Any executable script placed in `/usr/local/bin/entrypoint.d/` (or the project's `entrypoint.d/` folder before build) will be executed in alphabetical order during container startup.

### Included Packages

The image comes pre-installed with a curated set of essential tools:

- **Shell**: `bash`, `zsh`
- **Editors**: `vim`, `nano`
- **Network**: `curl`, `wget`, `rsync`, `git`
- **Utils**: `sudo`, `ca-certificates`, `tzdata`

## Development

```bash
docker buildx create --use --name build --node build --driver-opt network=host
docker buildx build -t snowdreamtech/alpine --platform=linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64,linux/ppc64le,linux/riscv64,linux/s390x . --push
```

### Project Tooling

This project uses the Snowdream Tech AI IDE Template for advanced automation.

| Suite        | Goal                       | Commands                                |
| :----------- | :------------------------- | :-------------------------------------- |
| **Core**     | Onboarding & Project Setup | `init`, `setup`, `install`, `check-env` |
| **Quality**  | Reliability & Standards    | `test`, `lint`, `format`, `verify`      |
| **Security** | Auditing & Compliance      | `audit`, `env`                          |
| **Ops**      | Building & Releasing       | `build`, `release`, `archive-changelog` |
| **Maint**    | Tooling & Cleanup          | `update`, `cleanup`                     |
| **DX**       | Developer Productivity     | `docs`, `commit`, `bench`               |

For more details on the AI-first development workflow, refer to the [CONVENTIONS.md](CONVENTIONS.md).

## Reference

1. [使用 buildx 构建多平台 Docker 镜像](https://icloudnative.io/posts/multiarch-docker-with-buildx/)
1. [如何使用 docker buildx 构建跨平台 Go 镜像](https://waynerv.com/posts/building-multi-architecture-images-with-docker-buildx/#buildx-%E7%9A%84%E8%B7%A8%E5%B9%B3%E5%8F%B0%E6%9E%84%E5%BB%BA%E7%AD%96%E7%95%A5)
1. [Building Multi-Arch Images for Arm and x86 with Docker Desktop](https://www.docker.com/blog/multi-arch-images/)
1. [How to Rapidly Build Multi-Architecture Images with Buildx](https://www.docker.com/blog/how-to-rapidly-build-multi-architecture-images-with-buildx/)
1. [Faster Multi-Platform Builds: Dockerfile Cross-Compilation Guide](https://www.docker.com/blog/faster-multi-platform-builds-dockerfile-cross-compilation-guide/)
1. [docker/buildx](https://github.com/docker/buildx)

---

Copyright (c) 2024-present [SnowdreamTech Inc.](https://github.com/snowdreamtech)
