#!/usr/bin/env bats

setup() {
  load '../node_modules/bats-support/load.bash'
  load '../node_modules/bats-assert/load.bash'

  # Create a temporary workspace
  export TEMP_DIR
  TEMP_DIR="$(mktemp -d)"
  mkdir -p "$TEMP_DIR/scripts/lib"
  cp "scripts/install.sh" "$TEMP_DIR/scripts/"
  cp "scripts/setup.sh" "$TEMP_DIR/scripts/"
  cp "scripts/lib/common.sh" "$TEMP_DIR/scripts/lib/"

  # Create a dummy project structure
  cd "$TEMP_DIR" || exit
  touch Makefile LICENSE README.md
  echo '{"name":"test-project"}' >package.json
  git init -q
}

teardown() {
  rm -rf "$TEMP_DIR"
}

@test "install.sh: dry-run reports planned installations" {
  run sh scripts/install.sh --dry-run
  assert_success
  assert_output --partial "Running in DRY-RUN mode"
  assert_output --partial "Installing Project Dependencies"
}

@test "install.sh: respects project root guard" {
  mkdir nested && cd nested || exit
  run sh ../scripts/install.sh
  assert_failure
  assert_output --partial "Error: This script must be run from the project root."
}

@test "setup.sh: dry-run reports planned tool setups" {
  run sh scripts/setup.sh --dry-run
  assert_success
  assert_output --partial "Running in DRY-RUN mode"
  # setup.sh has many components
  assert_output --partial "Setting up Node.js & pnpm"
  assert_output --partial "Setting up Python Virtual Environment"
  assert_output --partial "Setting up Pre-commit Hooks"
}

@test "setup.sh: respects project root guard" {
  mkdir nested && cd nested || exit
  run sh ../scripts/setup.sh
  assert_failure
  assert_output --partial "Error: This script must be run from the project root."
}
