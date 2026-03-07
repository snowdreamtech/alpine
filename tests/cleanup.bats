#!/usr/bin/env bats

setup() {
  load '../node_modules/bats-support/load.bash'
  load '../node_modules/bats-assert/load.bash'

  # Create a temporary workspace
  export TEMP_DIR
  TEMP_DIR="$(mktemp -d)"
  mkdir -p "$TEMP_DIR/scripts/lib"
  cp "scripts/cleanup.sh" "$TEMP_DIR/scripts/"
  cp "scripts/lib/common.sh" "$TEMP_DIR/scripts/lib/"

  # Create a dummy project structure
  cd "$TEMP_DIR" || exit
  touch Makefile LICENSE
  git init -q

  # Create targets to clean
  mkdir -p build dist .venv node_modules docs/.vitepress/dist
  touch build/dummy.o dist/bundle.js .venv/pip-installed node_modules/package docs/.vitepress/dist/index.html
  touch .python-version .pytest_cache coverage.xml
}

teardown() {
  rm -rf "$TEMP_DIR"
}

@test "cleanup.sh: dry-run reports what will be deleted without removing files" {
  run sh scripts/cleanup.sh --dry-run
  assert_success
  assert_output --partial "Running in DRY-RUN mode"
  assert_output --partial "Would remove Build artifacts (build)"
  assert_output --partial "Would remove Python virtual environment (.venv)"

  # Ensure files still exist
  [ -d "build" ]
  [ -d ".venv" ]
}

@test "cleanup.sh: live run removes target directories and files" {
  run sh scripts/cleanup.sh
  assert_success

  # Ensure targets are removed
  [ ! -d "build" ]
  [ ! -d "dist" ]
  [ ! -d ".venv" ]
  [ ! -f ".pytest_cache" ]

  # Ensure node_modules is NOT removed (verified in cleanup.sh logic)
  [ -d "node_modules" ]
}

@test "cleanup.sh: respects project root guard" {
  mkdir nested && cd nested || exit
  # No Makefile or .git here
  run sh ../scripts/cleanup.sh
  assert_failure
  assert_output --partial "Error: This script must be run from the project root."
}
