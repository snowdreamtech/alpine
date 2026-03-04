# 07 · Git

> Branch strategy, commit discipline, PR workflow, and history hygiene.

::: tip Source
This page summarizes [`.agent/rules/07-git.md`](https://github.com/snowdreamtech/template/blob/main/.agent/rules/07-git.md).
:::

## Branch Strategy

This project follows **trunk-based development** with short-lived feature branches:

```
main                          ← production, always deployable
 ├── feat/add-user-auth       ← feature branch (< 2 days ideally)
 ├── fix/nil-pointer-login    ← bug fix branch
 └── chore/update-deps        ← maintenance branch
```

**Rules:**

- `main` is always releasable — never break it
- Feature branches live ≤ 2 days before merging
- No direct commits to `main` (enforced by branch protection)

## Atomic Commits (MANDATORY)

Every commit must be a single, coherent, independently buildable unit:

```bash
# ✅ Atomic — one change, clear message
git commit -m "feat(auth): add JWT refresh token rotation"

# ❌ Non-atomic — mixed concerns
git commit -m "add auth, fix typos, update deps"
```

**Never** mix formatting changes with logic changes. Use separate commits.

## Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>
```

Enforced by `commitlint` on every commit via pre-commit hooks.

## Pull Request Workflow

1. Fork / create feature branch from `main`
2. Make atomic commits with descriptive messages
3. Open a PR with a clear title and description
4. All CI checks must pass
5. At least 1 code review approval required
6. Squash merge (to keep `main` history clean) OR rebase merge

## Tags & Releases

- Use annotated tags for releases: `git tag -a v1.0.0 -m "Release v1.0.0"`
- Follow [Semantic Versioning](https://semver.org/)
- Never delete or rewrite tags that have been pushed

## History Hygiene

- Never force-push to `main`
- Avoid `--no-ff` merges that clutter history with empty merge commits
- Use `git rebase -i` to clean up WIP commits before opening a PR
- Commit `.gitignore` changes in a dedicated chore commit
