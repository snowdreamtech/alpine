#!/usr/bin/env bats

setup() {
  load '../vendor/bats-support/load.bash'
  load '../vendor/bats-assert/load.bash'

  # Create a temporary workspace
  export TEMP_DIR
  unset _SNOWDREAM_TOP_LEVEL_SCRIPT
  TEMP_DIR="$(mktemp -d)"
  mkdir -p "$TEMP_DIR/scripts/lib"

  # Prevent parent orchestration scripts (like test.sh) from turning off logs
  unset _SNOWDREAM_TOP_LEVEL_SCRIPT

  # Copy functional scripts
  for f in archive-changelog.sh audit.sh cleanup.sh commit.sh release.sh update.sh verify.sh check-env.sh lint.sh test.sh; do
    cp "scripts/$f" "$TEMP_DIR/scripts/"
  done
  cp "scripts/lib/common.sh" "$TEMP_DIR/scripts/lib/"

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
  assert_output --partial "Security Audit Execution Summary"
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
  assert_output --partial "Update Execution Summary"
}

@test "maintenance: verify.sh dry-run reports orchestration" {
  run sh scripts/verify.sh --dry-run
  assert_success
  assert_output --partial "Starting Full Project Verification"
}
