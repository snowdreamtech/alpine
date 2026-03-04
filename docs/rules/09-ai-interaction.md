# 09 · AI Interaction

> Behavioral boundaries for AI assistants working within this repository.

::: tip Source
This page summarizes [`.agent/rules/09-ai-interaction.md`](https://github.com/snowdreamtech/template/blob/main/.agent/rules/09-ai-interaction.md).
:::

## Safety & Boundaries

AI assistants operating in this repository MUST:

- **Never** execute destructive commands (`rm -rf`, `DROP TABLE`, force-pushes) without explicit user confirmation
- **Never** commit secrets, credentials, or tokens — even in test code
- **Always** validate that changes are safe before proposing them
- **Always** explain what a command does before running it, especially in CI scripts
- **Stop and ask** when requirements are ambiguous — do not guess

## Scope of Work

AI assistants should:

- Work within the established architecture (see [03 · Architecture](./03-architecture))
- Follow all rules in `.agent/rules/` without exception
- Prefer the simplest correct solution over clever over-engineering
- Propose changes file by file, in atomic commits

AI assistants should NOT:

- Refactor unrelated code as a side effect of other changes
- Install new global tools or change system configuration without asking
- Modify rule files (`/.agent/rules/`) without explicit user instruction

## Code Generation Quality

All AI-generated code must:

- Pass the full pre-commit hook suite (`pre-commit run --all-files`)
- Include appropriate tests
- Follow the naming and style conventions in [02 · Coding Style](./02-coding-style)
- Use exact version pins for any new dependencies (see [05 · Dependencies](./05-dependencies))

## Communication Style

- Use Simplified Chinese (简体中文) for all user-facing responses
- Use English for code, comments, and commit messages
- Be concise — avoid repeating what the user already knows
- Use Markdown formatting with headers and code blocks for clarity
- Use appropriate emoji to structure responses (not excessively)

## Workflow Compliance

Before starting any significant work, check:

1. Are there existing workflows in `.agent/workflows/` that apply?
2. Are there existing patterns in the codebase to follow?
3. Are the requirements clear enough to proceed, or should clarification be sought?
