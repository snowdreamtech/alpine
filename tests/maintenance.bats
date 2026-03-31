#!/usr/bin/env bats

setup() {
  load 'vendor/bats-support/load.bash'
  load 'vendor/bats-assert/load.bash'

  # Create a temporary workspace
  export TEMP_DIR
  unset _SNOWDREAM_TOP_LEVEL_SCRIPT
  unset _G_PROJECT_ROOT
  unset _G_LIB_DIR
  TEMP_DIR="$(mktemp -d)"
  # Copy functional scripts
  cp -r scripts "$TEMP_DIR/"

  # Create a dummy project structure
  cd "$TEMP_DIR" || exit
  touch Makefile LICENSE README.md package.json
  mkdir -p docs tests .agent/rules && touch .agent/rules/01-general.md
  echo "repos: []" >.pre-commit-config.yaml

  # Create a proper CHANGELOG.md for archive-changelog test
  printf "# Changelog\n\n## [v2.0.0]\n- Current\n\n## [v1.0.0]\n- Old\n" >CHANGELOG.md

  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create a dummy .mise.toml for get_mise_tool_version
  cat <<EOF >.mise.toml
[tools]
node = "20.18.3"
pnpm = "10.30.3"
python = "3.12.9"
gitleaks = "8.30.0"
osv-scanner = "2.3.3"
trivy = "0.69.3"
zizmor = "1.3.1"
shfmt-py = "3.12.0.2"
shellcheck-py = "0.11.0.1"
actionlint-py = "1.7.11.24"
editorconfig-checker = "3.6.1"
checkmake = "0.3.2"
EOF

  # Mock tools for check-env.sh (called by release.sh and verify.sh)
  mkdir -p "$TEMP_DIR/bin"
  export PATH="$TEMP_DIR/bin:$PATH"

  printf '#!/usr/bin/env sh\necho "v20.18.3"\n' >"$TEMP_DIR/bin/node"
  printf '#!/usr/bin/env sh\necho "10.30.3"\n' >"$TEMP_DIR/bin/pnpm"
  printf '#!/usr/bin/env sh\necho "git version 2.30.0"\n' >"$TEMP_DIR/bin/git"
  printf '#!/usr/bin/env sh\necho "GNU Make 3.81"\n' >"$TEMP_DIR/bin/make"
  printf '#!/usr/bin/env sh\necho "3.6.1"\n' >"$TEMP_DIR/bin/editorconfig-checker"
  printf '#!/usr/bin/env sh\necho "v2026.3.8"\n' >"$TEMP_DIR/bin/mise"
  printf '#!/usr/bin/env sh\necho "v8.30.0"\n' >"$TEMP_DIR/bin/gitleaks"
  printf '#!/usr/bin/env sh\necho "v2.3.3"\n' >"$TEMP_DIR/bin/osv-scanner"
  printf '#!/usr/bin/env sh\necho "v0.69.3"\n' >"$TEMP_DIR/bin/trivy"
  printf '#!/usr/bin/env sh\necho "0.3.2"\n' >"$TEMP_DIR/bin/checkmake"
  printf '#!/usr/bin/env sh\necho "v1.3.1"\n' >"$TEMP_DIR/bin/zizmor"
  printf '#!/usr/bin/env sh\necho "3.12.0.2"\n' >"$TEMP_DIR/bin/shfmt"
  printf '#!/usr/bin/env sh\necho "0.11.0.1"\n' >"$TEMP_DIR/bin/shellcheck"
  printf '#!/usr/bin/env sh\necho "1.7.11.24"\n' >"$TEMP_DIR/bin/actionlint"
  chmod +x "$TEMP_DIR/bin/"*
}

teardown() {
  rm -rf "$TEMP_DIR"
}

@test "maintenance: archive-changelog.sh dry-run reports archival plans" {
  echo '{"version":"2.0.0"}' >package.json
  run sh scripts/archive-changelog.sh --dry-run
  assert_success
  assert_output --partial "DRY-RUN: Would create ./CHANGELOG-v1.md"
}

@test "maintenance: audit.sh dry-run reports security scans" {
  run sh scripts/audit.sh --dry-run
  assert_success
  assert_output --partial "Audit complete"
}

@test "maintenance: cleanup.sh dry-run reports cleanup activities" {
  run sh scripts/cleanup.sh --dry-run
  assert_success
  assert_output --partial "Starting deep project cleanup"
}

@test "maintenance: commit.sh dry-run reports commit process" {
  run sh scripts/commit.sh --dry-run
  assert_success
  assert_output --partial "Starting Structured Commit Guide"
}

@test "maintenance: release.sh dry-run reports release steps" {
  run sh scripts/release.sh --dry-run
  assert_success
  assert_output --partial "Starting Standardized Release Process"
}

@test "maintenance: update.sh dry-run reports tool updates" {
  run sh scripts/update.sh --dry-run
  assert_success
  assert_output --partial "Update complete"
}

@test "maintenance: verify.sh dry-run reports orchestration" {
  run sh scripts/verify.sh --dry-run
  assert_success
  assert_output --partial "Starting Full Project Verification"
}
