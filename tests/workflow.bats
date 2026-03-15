#!/usr/bin/env bats

setup() {
  load '../vendor/bats-support/load.bash'
  load '../vendor/bats-assert/load.bash'

  # Create a temporary workspace
  export TEMP_DIR
  unset _SNOWDREAM_TOP_LEVEL_SCRIPT
  TEMP_DIR="$(mktemp -d)"
  mkdir -p "$TEMP_DIR/scripts/lib"

  # Copy functional scripts
  for f in build.sh format.sh lint.sh test.sh docs.sh bench.sh; do
    cp "scripts/$f" "$TEMP_DIR/scripts/"
  done
  cp "scripts/lib/common.sh" "$TEMP_DIR/scripts/lib/"

  # Create a dummy project structure
  cd "$TEMP_DIR" || exit
  touch Makefile LICENSE README.md package.json
  mkdir -p docs tests .agent/rules && touch .agent/rules/01-general.md
  echo "repos: []" >.pre-commit-config.yaml
  git init -q

  # Mock tools for check-env.sh (called by orchestration scripts)
  mkdir -p "$TEMP_DIR/bin"
  export PATH="$TEMP_DIR/bin:$PATH"

  printf '#!/bin/sh\necho "v20.18.3"\n' >"$TEMP_DIR/bin/node"
  printf '#!/bin/sh\necho "9.0.0"\n' >"$TEMP_DIR/bin/pnpm"
  printf '#!/bin/sh\necho "git version 2.30.0"\n' >"$TEMP_DIR/bin/git"
  printf '#!/bin/sh\necho "GNU Make 3.81"\n' >"$TEMP_DIR/bin/make"
  printf '#!/bin/sh\necho "3.6.1"\n' >"$TEMP_DIR/bin/editorconfig-checker"
  printf '#!/bin/sh\necho "v2026.3.8"\n' >"$TEMP_DIR/bin/mise"
  chmod +x "$TEMP_DIR/bin/"*
}

teardown() {
  rm -rf "$TEMP_DIR"
}

@test "workflow: build.sh dry-run reports build activities" {
  run sh scripts/build.sh --dry-run
  assert_success
  assert_output --partial "Starting Project Build"
}

@test "workflow: format.sh dry-run reports formatting tasks" {
  run sh scripts/format.sh --dry-run
  assert_success
  assert_output --partial "Starting Unified Project Formatter"
}

@test "workflow: lint.sh dry-run reports linting scans" {
  run sh scripts/lint.sh --dry-run
  assert_success
  assert_output --partial "Starting Unified Project Linter"
}

@test "workflow: test.sh dry-run reports test execution" {
  run sh scripts/test.sh --dry-run
  assert_success
  assert_output --partial "Starting Unified Test Runner"
}

@test "workflow: docs.sh dry-run reports documentation generation" {
  run sh scripts/docs.sh --dry-run
  assert_success
  assert_output --partial "Documentation Manager"
}

@test "workflow: bench.sh dry-run reports benchmarking" {
  run sh scripts/bench.sh --dry-run
  assert_success
  assert_output --partial "Starting Performance Benchmarker"
}
