<!-- DO NOT EDIT MANUALLY - This file is managed by automated professional tools -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.23.3-1] - 2026-03-12

### Added

- **Base Image**: High-performance Alpine 3.23.3 base with multi-arch support.
- **User Mapping**: Robust `PUID`/`PGID` support with automatic home directory permission repairs.
- **Initialization**: Modular `entrypoint.d` mechanism for decoupled downstream setup.
- **Timezone**: Dynamic `TZ` configuration support in entrypoint.
- **Capabilities**: Support for `CAP_NET_BIND_SERVICE` to allow unprivileged port binding.
- **Privileges**: Automatic passwordless `sudo` and `doas` configuration for mapped non-root users.
- **Tooling**: Built-in `bash`, `zsh`, `nano`, `rsync`, `git`, `curl`, `jq`, and more.
- **CI/CD**: Docker-specific targets in `Makefile` and integration tests in `tests/docker.bats`.

### Fixed

- **Non-root Compliance**: Guarded root-only operations in entrypoint to prevent crashes when running as non-root.
- **POSIX Safety**: Patched entrypoint scripts against shell-specific null parameter crashes and formatting issues.

### Security

- Hardened user/group mapping and hardened su-exec execution patterns.
- Pre-installed security tools (gnupg, openssl, ca-certificates).

[3.23.3-1]: https://github.com/snowdreamtech/alpine/compare/upstream/dev...dev

[Unreleased]: https://github.com/snowdreamtech/template/commits/main/
