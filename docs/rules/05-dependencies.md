# 05 · Dependencies

> Standards for dependency management, version pinning, and supply-chain security.

::: tip Source
This page summarizes [`.agent/rules/05-dependencies.md`](https://github.com/snowdreamtech/template/blob/main/.agent/rules/05-dependencies.md).
:::

## Strict Version Pinning (MANDATORY)

All dependencies in every language and package manager **MUST** use exact version numbers. Never use version ranges, wildcards, or operators that allow floating versions.

| ❌ Wrong             | ✅ Correct            |
| -------------------- | --------------------- |
| `"lodash": "^4.0.0"` | `"lodash": "4.17.21"` |
| `requests>=2.0`      | `requests==2.28.2`    |
| `"spring-boot:3.+"`  | `"spring-boot:3.2.5"` |

**Rationale**: Floating versions break reproducibility, make audits impossible, and open the door to supply-chain attacks where a malicious version satisfies your range constraint.

## Lock Files

Every project MUST commit its lock file to version control:

| Package Manager   | Lock File                                      |
| ----------------- | ---------------------------------------------- |
| npm               | `package-lock.json`                            |
| pnpm              | `pnpm-lock.yaml`                               |
| Yarn              | `yarn.lock`                                    |
| Bun               | `bun.lockb`                                    |
| pip / uv / Poetry | `requirements.txt` / `uv.lock` / `poetry.lock` |
| Composer          | `composer.lock`                                |
| Go modules        | `go.sum`                                       |
| Cargo             | `Cargo.lock`                                   |
| Bundler           | `Gemfile.lock`                                 |
| NuGet             | `packages.lock.json`                           |
| Swift PM          | `Package.resolved`                             |

## CI Installation

Always use the frozen/locked install command in CI to guarantee the lock file is respected:

```bash
npm ci                                # npm
pnpm install --frozen-lockfile        # pnpm
yarn install --frozen-lockfile        # Yarn
bun install --frozen-lockfile         # Bun
pip install -r requirements.txt       # pip
poetry install --no-root              # Poetry
go mod download                       # Go
cargo build                           # Cargo (uses Cargo.lock)
bundle install --frozen               # Bundler
```

## Dependency Auditing

Run security audits in CI for every ecosystem in use:

```bash
npm audit --audit-level=high
pnpm audit --audit-level=high
pip-audit
govulncheck ./...
cargo audit
bundle-audit check --update
```

## Updating Dependencies

1. Update one dependency at a time with a single focused PR
2. Review the changelog before updating
3. Pin to the new exact version after verification
4. Run the full test suite before merging
