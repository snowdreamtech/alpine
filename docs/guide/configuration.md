# Configuration

## Project Hydration

After cloning from the template, run the hydration script to replace all placeholder values:

```bash
bash scripts/init-project.sh
```

The script walks you through:

| Placeholder     | Example          |
| --------------- | ---------------- |
| `template`      | `my-awesome-app` |
| `snowdreamtech` | `myorg`          |
| `snowdream`     | `johndoe`        |

It replaces these strings throughout all files and optionally re-initializes the Git repository.

## Environment Variables

The project uses `.env` files for local configuration (excluded from Git via `.gitignore`):

```bash
cp .env.example .env  # if .env.example exists
```

## Pre-commit Configuration

Pre-commit hooks are defined in `.pre-commit-config.yaml`. To disable a hook temporarily:

```yaml
# Comment out the hook
# - id: hadolint
```

To skip hooks for a single commit (emergency use only):

```bash
git commit --no-verify -m "chore: emergency fix"
```
