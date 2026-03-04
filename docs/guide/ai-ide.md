# AI IDE Integration

The template provides out-of-the-box support for 50+ AI coding assistants.

## How It Works

Each AI IDE expects its configuration in a specific directory. This template creates a directory for every supported IDE, each containing:

1. **`rules/`** — Points to the canonical rules in `.agent/rules/`
2. **`commands/` or `workflows/`** — Points to SpecKit workflow shortcuts

```text
.agent/rules/          ← Single Source of Truth (you edit here)
     ↑
     │  mirrors
     │
.cursor/rules/         ← Cursor IDE reads from here
.cline/rules/          ← Cline reads from here
.windsurf/rules/       ← Windsurf reads from here
.aide/rules/           ← Aide reads from here
... (50+ total)
```

## Supported AI IDEs

### Tier 1 — Widely Used

| IDE            | Directory    | Rules             | Commands     |
| -------------- | ------------ | ----------------- | ------------ |
| Cursor         | `.cursor/`   | ✅                | ✅           |
| Windsurf       | `.windsurf/` | ✅                | ✅           |
| GitHub Copilot | `.github/`   | ✅ (instructions) | ✅ (prompts) |
| Cline          | `.cline/`    | ✅                | ✅           |
| Roo Code       | `.roo/`      | ✅                | ✅           |
| Claude Code    | `.claude/`   | ✅                | ✅           |
| Gemini         | `.gemini/`   | ✅                | ✅           |
| Continue       | `.continue/` | ✅                | ✅           |
| Amazon Q       | `.amazonq/`  | ✅                | ✅           |
| Kiro           | `.kiro/`     | ✅                | ✅           |

### Tier 2 — Emerging Tools

| IDE       | Directory     | Rules | Commands |
| --------- | ------------- | ----- | -------- |
| Trae      | `.trae/`      | ✅    | ✅       |
| Aide      | `.aide/`      | ✅    | ✅       |
| OpenHands | `.openhands/` | ✅    | ✅       |
| Devin     | `.devin/`     | ✅    | ✅       |
| Augment   | `.augment/`   | ✅    | ✅       |
| Codex     | `.codex/`     | ✅    | ✅       |
| Goose     | `.goose/`     | ✅    | ✅       |
| Kilocode  | `.kilocode/`  | ✅    | ✅       |
| Junie     | `.junie/`     | ✅    | ✅       |
| Zed AI    | `.zed/`       | ✅    | ✅       |

### Tier 3 — Specialized / Niche

Includes `.adal`, `.aiassistant`, `.bito`, `.blackbox`, `.bob`, `.codebuddy`, `.codegeex`, `.codeium`, `.cody`, `.commandcode`, `.cortex`, `.crush`, `.factory`, `.iflow`, `.mcpjam`, `.melty`, `.mux`, `.neovate`, `.opencode`, `.pearai`, `.pi`, `.pochi`, `.qoder`, `.qwen`, `.shai`, `.supermaven`, `.tabnine`, `.vibe`, `.void`, `.zencoder`, and more.

## Adding a New IDE

If your AI tool isn't listed, adding support takes 2 steps:

1. **Create the directory structure**:

   ```bash
   mkdir -p .your-ide/rules
   mkdir -p .your-ide/commands
   ```

2. **Create the redirect rules file** (copy from `.cline/rules/rules.md` as template):

   ```bash
   cp .cline/rules/rules.md .your-ide/rules/rules.md
   ```

3. **Open a PR** to contribute it back to the template!

## Custom Instructions Per IDE

While the rules system provides unified behavior, you can add IDE-specific extensions by placing additional `.md` files alongside the `rules.md` redirect. These are additive — they extend, not replace, the core rules.
