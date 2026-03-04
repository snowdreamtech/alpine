# Node.js Development Guidelines

## 1. Package Management

- **npm**: Use `npm` for package management. Ensure `package-lock.json` is always committed.
- **Dependency Management**:
  - `dependencies`: Runtime requirements only.
  - `devDependencies`: Build tools, linters, test frameworks.
  - `peerDependencies`: When creating plugins or shared libraries.
- **Strict Version Pinning (MANDATORY)**: All dependencies in `package.json` MUST use **exact version numbers**. Never use range operators (`^`, `~`, `>=`, `*`, `latest`). Unpinned versions introduce non-reproducible builds and undiscovered breaking changes.

  ```jsonc
  // ❌ WRONG — version ranges are non-deterministic
  "dependencies": {
    "express": "^4.18.0",
    "lodash": "~4.17.0",
    "axios": ">=1.0.0"
  }

  // ✅ CORRECT — exact, auditable, reproducible
  "dependencies": {
    "express": "4.18.2",
    "lodash": "4.17.21",
    "axios": "1.6.7"
  }
  ```

  Always commit `package-lock.json` to version control. Use `npm ci` (not `npm install`) in CI pipelines for deterministic installs.
- **Scripts**: All repeatable actions MUST be defined in `npm scripts` within `package.json`.

## 2. Environment Setup

- **Node Version**: Check `.node-version` or `engines` field in `package.json`.
- **Security**:

  ```bash
  npm audit     # check for vulnerabilities
  npm ci --ignore-scripts   # faster, more secure — disable postinstall scripts in CI
  ```

## 3. Tool Execution (Performance First)

- **Anti-npx Policy**: Avoid `npx` for frequently used tools (lint, format, test). Its startup overhead is significant.
- **Preferred Method**: Use direct execution of pre-installed binaries (via `make setup`).
- **Local Path**: For project-specific tools, use `npm run <command>` which safely includes `node_modules/.bin` in the path without `npx` overhead.

  ```bash
  npm run dev          # dev
  tsc && node dist/index.js # prod
  lint-staged
  ```

## 4. Coding Style

- **Strict Mode**: Always use `"use strict";` or enable it via TypeScript.
- **Async/Await**: Prefer `async/await` over raw Promises or callbacks.
- **Module System**: Use ESM (`import`/`export`) for new code. Reference `.aiconfig` for module configuration.

## 5. Testing & Quality

- **Testing**: Use `Vitest` or `Jest`. Ensure all logic has corresponding unit tests.
- **Linting**: Consistent linting via `ESLint` and `Prettier`.
- **Pre-commit**: Always run `make lint` before pushing to ensure all checks pass.
