# GitHub Actions Workflows Guide

[简体中文](file:///Users/snowdream/Workspace/snowdreamtech/template/.github/workflows/README_zh-CN.md) | [English](file:///Users/snowdream/Workspace/snowdreamtech/template/.github/workflows/README.md)

This directory contains the automated CI/CD pipelines and repository maintenance tasks for the Snowdream Tech project.

## 1. Design & Architecture

The CI/CD system follows the **Triple Guarantee (三重保证)** quality mechanism:

1. **Local Hooks**: `pre-commit` for instant feedback.
2. **CI Pipeline**: Rigorous verification on every pull request.
3. **Continuous Delivery**: Automated versioning and deployment.

### Core Principles

- **Least Privilege**: All workflows run with the minimum GITHUB_TOKEN scope.
- **Fail Fast**: Aggressive timeouts and parallel execution ensure rapid feedback.
- **Traceability**: Structured headers and "Why" comments explain every design decision.
- **Idempotency**: All verification steps are designed to be repeatable and safe.

## 2. Usage Guide

Most workflows are automatic. You can manually trigger them via the **Actions** tab in GitHub using `workflow_dispatch`.

### Key Workflows

| Workflow             | Responsibility                | Trigger      |
| :------------------- | :---------------------------- | :----------- |
| `lint.yml`           | Code quality & Security audit | Push/PR      |
| `test.yml`           | Multi-language test suite     | Push/PR      |
| `verify.yml`         | Pre-flight environment check  | Push/PR      |
| `release-please.yml` | Automated versioning          | Push to main |
| `pages.yml`          | Documentation site deploy     | Docs change  |

## 3. Operations Guide

### Troubleshooting

- **Permission Denied**: Check the `permissions` block in the workflow header.
- **Action Pinning**: Ensure actions use `x.y.z` tags for stability.
- **Timeout**: Some matrix tests (e.g., Go/Python) may require increased `timeout-minutes`.

## 4. Security Considerations

- **Secret Handling**: Never log secrets. Always pass them via env vars in `run:` steps.
- **Action Supply Chain**: Use stable semantic version tags for all external actions.
- **OIDC**: Used for cloud integrations to avoid long-lived credentials.

## 5. Development Guide

To add a new workflow:

1. Create a `.yml` file in this directory.
2. Follow the **World Class AI Documentation** header template.
3. Enforce `shell: sh` for cross-platform compatibility.
4. Run `make verify` and `actionlint` locally before committing.
