#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# scripts/gen-dependabot.sh - Smart Dependabot Configuration Generator
#
# Purpose:
#   Scans the repository for manifest/lockfiles across all supported ecosystems
#   and generates a minimal, accurate .github/dependabot.yml that only includes
#   ecosystems actually present in the project.
#
# Usage:
#   sh scripts/gen-dependabot.sh [--dry-run]
#
# Design:
#   - Uses `git ls-files` to respect .gitignore automatically.
#   - Deduplicates (ecosystem, directory) pairs.
#   - POSIX-compliant sh logic (no bash-isms).
#   - Idempotent: same input always produces same output.

set -e

# ── Configuration ────────────────────────────────────────────────────────────
TARGET_BRANCH="dev"
DEPENDABOT_FILE=".github/dependabot.yml"
DRY_RUN=0

# ── Label Mapping ────────────────────────────────────────────────────────────
# Purpose: Returns the ecosystem-specific label for Dependabot PR labeling.
# Params:
#   $1 - Dependabot ecosystem name
get_label() {
  case "$1" in
    github-actions) echo "github-actions" ;;
    npm | bun) echo "javascript" ;;
    pip | conda | uv) echo "python" ;;
    gomod) echo "go" ;;
    cargo | rust-toolchain) echo "rust" ;;
    composer) echo "php" ;;
    bundler) echo "ruby" ;;
    docker) echo "docker" ;;
    mix) echo "elixir" ;;
    elm) echo "elm" ;;
    gitsubmodule) echo "git" ;;
    gradle | maven) echo "java" ;;
    nuget | dotnet-sdk) echo "dotnet" ;;
    pub) echo "dart" ;;
    swift) echo "swift" ;;
    terraform | opentofu) echo "terraform" ;;
    devcontainers) echo "devcontainers" ;;
    bazel) echo "bazel" ;;
    helm) echo "kubernetes" ;;
    julia) echo "julia" ;;
    pre-commit) echo "pre-commit" ;;
    vcpkg) echo "cpp" ;;
    *) echo "other" ;;
  esac
}

# ── Detection Engine ─────────────────────────────────────────────────────────
# Purpose: Checks if any git-tracked file matches the given glob patterns.
# Params:
#   $@ - One or more glob patterns to match against tracked files
# Returns: 0 if at least one match found, 1 otherwise
has_tracked_file() {
  for _pattern in "$@"; do
    # Use git ls-files with glob matching; returns non-empty if matched
    if git ls-files --error-unmatch "$_pattern" >/dev/null 2>&1; then
      return 0
    fi
  done
  return 1
}

# Purpose: Finds all directories containing files matching the given patterns.
#   Returns unique, sorted directory paths in Dependabot format (e.g., "/" or "/docs").
# Params:
#   $@ - One or more glob patterns
find_dirs_for_patterns() {
  _FOUND_DIRS=""
  for _pattern in "$@"; do
    # List matching tracked files, extract directory, convert to Dependabot format
    _matches=$(git ls-files "$_pattern" 2>/dev/null || true)
    if [ -n "$_matches" ]; then
      _new_dirs=$(echo "$_matches" | while IFS= read -r _file; do
        _dir=$(dirname "$_file")
        if [ "$_dir" = "." ]; then
          echo "/"
        else
          echo "/$_dir"
        fi
      done)
      _FOUND_DIRS="${_FOUND_DIRS}${_FOUND_DIRS:+
}${_new_dirs}"
    fi
  done
  # Deduplicate and sort
  if [ -n "$_FOUND_DIRS" ]; then
    echo "$_FOUND_DIRS" | sort -u
  fi
}

# ── YAML Emitter ─────────────────────────────────────────────────────────────
# Purpose: Emits a single Dependabot update entry in YAML format.
# Params:
#   $1 - Ecosystem name
#   $2 - Directory path (Dependabot format)
emit_entry() {
  _ecosystem="$1"
  _directory="$2"
  _label=$(get_label "$_ecosystem")

  # 1. Frequency Tiering: Core ecosystems daily, others weekly
  _interval="weekly"
  case "$_ecosystem" in
    npm | gomod | bun | pip | uv) _interval="daily" ;;
  esac

  # 3. Label Refinement: Add semantic labels
  _extra_labels=""
  case "$_ecosystem" in
    github-actions) _extra_labels="
      - \"devops\"" ;;
    docker | devcontainers) _extra_labels="
      - \"infrastructure\"" ;;
    pre-commit) _extra_labels="
      - \"linting\"" ;;
  esac

  cat <<EOF
  - package-ecosystem: "${_ecosystem}"
    directory: "${_directory}"
    target-branch: "${TARGET_BRANCH}"
    # 2. Open PR Limit: Prevent PR-bombing
    open-pull-requests-limit: 10
    # Consolidate updates to reduce PR noise
    groups:
      📦-all-patch-minor:
        update-types:
          - "patch"
          - "minor"
EOF

  # Add ecosystem-specific groups to further reduce noise
  if [ "$_ecosystem" = "npm" ]; then
    cat <<EOF
      🧹-lint-dependencies:
        patterns: ["eslint*", "prettier*", "stylelint*"]
      🧪-testing-frameworks:
        patterns: ["vitest*", "jest*", "playwright*", "cypress*"]
      ⚡-vite-suite:
        patterns: ["vite*", "@vitejs/*"]
EOF
  elif [ "$_ecosystem" = "github-actions" ]; then
    cat <<EOF
      🔧-actions-updates:
        patterns: ["*"]
EOF
  elif [ "$_ecosystem" = "docker" ] || [ "$_ecosystem" = "devcontainers" ]; then
    cat <<EOF
      🐳-base-images:
        patterns: ["alpine*", "ubuntu*", "debian*", "node*", "python*", "golang*"]
EOF
  elif [ "$_ecosystem" = "pre-commit" ]; then
    cat <<EOF
      🧹-pre-commit-hooks:
        patterns: ["*"]
EOF
  elif [ "$_ecosystem" = "gomod" ]; then
    cat <<EOF
      🧪-go-cloud-suite:
        patterns: ["google.golang.org/*", "github.com/aws/*", "github.com/azure/*"]
EOF
  fi

  cat <<EOF
    schedule:
      interval: "${_interval}"
    commit-message:
      prefix: "chore(deps):"
    labels:
      - "dependencies"
      - "${_label}"${_extra_labels}

EOF
}

# ── Ecosystem Scanner ────────────────────────────────────────────────────────
# Purpose: Scans for all supported ecosystems and emits entries.
#   Each ecosystem is checked via its canonical manifest files.
scan_ecosystems() {
  # Track emitted (ecosystem:directory) pairs for deduplication
  _EMITTED=""

  # Helper: emit only if not already emitted
  _emit_unique() {
    _key="${1}:${2}"
    case "$_EMITTED" in
      *"|${_key}|"*) return ;; # Already emitted
    esac
    _EMITTED="${_EMITTED}|${_key}|"
    emit_entry "$1" "$2"
  }

  # ── 1. GitHub Actions ────────────────────────────────────────────────────
  if has_tracked_file ".github/workflows/*.yml" ".github/workflows/*.yaml"; then
    _emit_unique "github-actions" "/"
  fi

  # ── 2. npm / pnpm / yarn ────────────────────────────────────────────────
  _npm_dirs=$(find_dirs_for_patterns "package.json" "**/package.json")
  if [ -n "$_npm_dirs" ]; then
    echo "$_npm_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "npm" "$_d"
    done
  fi

  # ── 3. pip (Python) ─────────────────────────────────────────────────────
  _pip_dirs=$(find_dirs_for_patterns "requirements.txt" "requirements-dev.txt" "setup.py" "setup.cfg" "Pipfile" "**/requirements.txt" "**/Pipfile")
  if [ -n "$_pip_dirs" ]; then
    echo "$_pip_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "pip" "$_d"
    done
  fi

  # ── 4. Go Modules ───────────────────────────────────────────────────────
  _go_dirs=$(find_dirs_for_patterns "go.mod" "**/go.mod")
  if [ -n "$_go_dirs" ]; then
    echo "$_go_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "gomod" "$_d"
    done
  fi

  # ── 5. Cargo (Rust) ─────────────────────────────────────────────────────
  _cargo_dirs=$(find_dirs_for_patterns "Cargo.toml" "**/Cargo.toml")
  if [ -n "$_cargo_dirs" ]; then
    echo "$_cargo_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "cargo" "$_d"
    done
  fi

  # ── 6. Composer (PHP) ───────────────────────────────────────────────────
  _composer_dirs=$(find_dirs_for_patterns "composer.json" "**/composer.json")
  if [ -n "$_composer_dirs" ]; then
    echo "$_composer_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "composer" "$_d"
    done
  fi

  # ── 7. Bundler (Ruby) ───────────────────────────────────────────────────
  _bundler_dirs=$(find_dirs_for_patterns "Gemfile" "**/Gemfile")
  if [ -n "$_bundler_dirs" ]; then
    echo "$_bundler_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "bundler" "$_d"
    done
  fi

  # ── 8. Docker ───────────────────────────────────────────────────────────
  _docker_dirs=$(find_dirs_for_patterns "Dockerfile" "**/Dockerfile" "Dockerfile.*" "**/Dockerfile.*")
  if [ -n "$_docker_dirs" ]; then
    echo "$_docker_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "docker" "$_d"
    done
  fi

  # ── 9. Mix (Elixir) ─────────────────────────────────────────────────────
  _mix_dirs=$(find_dirs_for_patterns "mix.exs" "**/mix.exs")
  if [ -n "$_mix_dirs" ]; then
    echo "$_mix_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "mix" "$_d"
    done
  fi

  # ── 10. Elm ──────────────────────────────────────────────────────────────
  _elm_dirs=$(find_dirs_for_patterns "elm.json" "**/elm.json")
  if [ -n "$_elm_dirs" ]; then
    echo "$_elm_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "elm" "$_d"
    done
  fi

  # ── 11. Git Submodules ───────────────────────────────────────────────────
  if has_tracked_file ".gitmodules"; then
    _emit_unique "gitsubmodule" "/"
  fi

  # ── 12. Gradle (Java/Kotlin) ─────────────────────────────────────────────
  _gradle_dirs=$(find_dirs_for_patterns "build.gradle" "build.gradle.kts" "**/build.gradle" "**/build.gradle.kts")
  if [ -n "$_gradle_dirs" ]; then
    echo "$_gradle_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "gradle" "$_d"
    done
  fi

  # ── 13. Maven (Java) ────────────────────────────────────────────────────
  _maven_dirs=$(find_dirs_for_patterns "pom.xml" "**/pom.xml")
  if [ -n "$_maven_dirs" ]; then
    echo "$_maven_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "maven" "$_d"
    done
  fi

  # ── 14. NuGet (C#/.NET) ──────────────────────────────────────────────────
  _nuget_files=$(git ls-files "*.csproj" "*.fsproj" "packages.config" "**/*.csproj" "**/*.fsproj" "**/packages.config" 2>/dev/null || true)
  if [ -n "$_nuget_files" ]; then
    _nuget_dirs=$(echo "$_nuget_files" | while IFS= read -r _f; do
      _d=$(dirname "$_f")
      [ "$_d" = "." ] && echo "/" || echo "/$_d"
    done | sort -u)
    echo "$_nuget_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "nuget" "$_d"
    done
  fi

  # ── 15. Pub (Dart/Flutter) ───────────────────────────────────────────────
  _pub_dirs=$(find_dirs_for_patterns "pubspec.yaml" "**/pubspec.yaml")
  if [ -n "$_pub_dirs" ]; then
    echo "$_pub_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "pub" "$_d"
    done
  fi

  # ── 16. Swift ────────────────────────────────────────────────────────────
  _swift_dirs=$(find_dirs_for_patterns "Package.swift" "**/Package.swift")
  if [ -n "$_swift_dirs" ]; then
    echo "$_swift_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "swift" "$_d"
    done
  fi

  # ── 17. Terraform ────────────────────────────────────────────────────────
  _tf_files=$(git ls-files "*.tf" "**/*.tf" 2>/dev/null | grep -v '\.terraform/' || true)
  if [ -n "$_tf_files" ]; then
    _tf_dirs=$(echo "$_tf_files" | while IFS= read -r _f; do
      _d=$(dirname "$_f")
      [ "$_d" = "." ] && echo "/" || echo "/$_d"
    done | sort -u)
    echo "$_tf_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "terraform" "$_d"
    done
  fi

  # ── 18. Dev Containers ──────────────────────────────────────────────────
  _dc_dirs=$(find_dirs_for_patterns "devcontainer.json" ".devcontainer.json" "**/devcontainer.json" "**/.devcontainer.json")
  if [ -n "$_dc_dirs" ]; then
    echo "$_dc_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "devcontainers" "$_d"
    done
  fi

  # ── 19. Bazel ────────────────────────────────────────────────────────────
  _bazel_dirs=$(find_dirs_for_patterns "MODULE.bazel" "WORKSPACE" "**/MODULE.bazel" "**/WORKSPACE")
  if [ -n "$_bazel_dirs" ]; then
    echo "$_bazel_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "bazel" "$_d"
    done
  fi

  # ── 20. Bun ──────────────────────────────────────────────────────────────
  _bun_dirs=$(find_dirs_for_patterns "bun.lockb" "bunfig.toml" "**/bun.lockb" "**/bunfig.toml")
  if [ -n "$_bun_dirs" ]; then
    echo "$_bun_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "bun" "$_d"
    done
  fi

  # ── 21. Conda ────────────────────────────────────────────────────────────
  _conda_dirs=$(find_dirs_for_patterns "environment.yml" "environment.yaml" "**/environment.yml" "**/environment.yaml")
  if [ -n "$_conda_dirs" ]; then
    echo "$_conda_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "conda" "$_d"
    done
  fi

  # ── 22. Helm ─────────────────────────────────────────────────────────────
  _helm_dirs=$(find_dirs_for_patterns "Chart.yaml" "**/Chart.yaml")
  if [ -n "$_helm_dirs" ]; then
    echo "$_helm_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "helm" "$_d"
    done
  fi

  # ── 23. Julia ────────────────────────────────────────────────────────────
  _julia_dirs=$(find_dirs_for_patterns "Project.toml" "**/Project.toml")
  if [ -n "$_julia_dirs" ]; then
    echo "$_julia_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "julia" "$_d"
    done
  fi

  # ── 24. Pre-Commit ──────────────────────────────────────────────────────
  if has_tracked_file ".pre-commit-config.yaml"; then
    _emit_unique "pre-commit" "/"
  fi

  # ── 25. Rust Toolchain ──────────────────────────────────────────────────
  if has_tracked_file "rust-toolchain.toml" "rust-toolchain"; then
    _emit_unique "rust-toolchain" "/"
  fi

  # ── 26. UV (Python) ─────────────────────────────────────────────────────
  _uv_dirs=$(find_dirs_for_patterns "uv.lock" "**/uv.lock")
  if [ -n "$_uv_dirs" ]; then
    echo "$_uv_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "uv" "$_d"
    done
  fi

  # ── 27. vcpkg (C/C++) ───────────────────────────────────────────────────
  _vcpkg_dirs=$(find_dirs_for_patterns "vcpkg.json" "**/vcpkg.json")
  if [ -n "$_vcpkg_dirs" ]; then
    echo "$_vcpkg_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "vcpkg" "$_d"
    done
  fi

  # ── 28. .NET SDK ─────────────────────────────────────────────────────────
  _dotnetsdk_dirs=$(find_dirs_for_patterns "global.json" "**/global.json")
  if [ -n "$_dotnetsdk_dirs" ]; then
    echo "$_dotnetsdk_dirs" | while IFS= read -r _d; do
      [ -n "$_d" ] && _emit_unique "dotnet-sdk" "$_d"
    done
  fi
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
  # Parse arguments
  for _arg in "$@"; do
    case "$_arg" in
      --dry-run) DRY_RUN=1 ;;
    esac
  done

  # Ensure we are in a git repository
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR: Not inside a git repository." >&2
    exit 1
  fi

  # Generate the YAML header
  _HEADER=$(cat <<'HEADER'
---
# Dependabot Version Updates (Auto-generated by scripts/gen-dependabot.sh)
#
# ⚠️  DO NOT EDIT MANUALLY — This file is regenerated automatically.
# To update, run: sh scripts/gen-dependabot.sh
# Or push to dev/main and the dependabot-sync workflow will update it.
#
# Purpose: Automatically maintains project dependencies to ensure security and stability.
# Target Branch: dev (Ensures updates are validated in development before production).
# Design:
#   - Only ecosystems with detected manifest files are included.
#   - Semantic 'chore(deps)' prefixing for clean version history.
#   - Automated labeling for improved maintenance visibility.

version: 2
updates:
HEADER
)

  # Generate entries
  _ENTRIES=$(scan_ecosystems)

  if [ -z "$_ENTRIES" ]; then
    echo "WARNING: No ecosystems detected. The generated file will have no update entries." >&2
  fi

  _OUTPUT="${_HEADER}
${_ENTRIES}"

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "# [DRY-RUN] Would write to ${DEPENDABOT_FILE}:"
    echo "$_OUTPUT"
  else
    mkdir -p "$(dirname "$DEPENDABOT_FILE")"
    echo "$_OUTPUT" > "$DEPENDABOT_FILE"
    echo "✅ Generated ${DEPENDABOT_FILE} successfully."

    # Show summary
    _COUNT=$(echo "$_ENTRIES" | grep -c 'package-ecosystem' || true)
    echo "   Ecosystems detected: ${_COUNT}"
  fi
}

main "$@"
