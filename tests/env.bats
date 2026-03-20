#!/usr/bin/env bats

setup() {
  load '../vendor/bats-support/load.bash'
  load '../vendor/bats-assert/load.bash'

  # Create a temporary workspace
  export TEMP_DIR
  unset _SNOWDREAM_TOP_LEVEL_SCRIPT
  TEMP_DIR="$(mktemp -d)"

  # Copy functional scripts
  cp -r scripts "$TEMP_DIR/"

  # Create a dummy project structure
  cd "$TEMP_DIR" || exit
  touch Makefile README.md package.json
  git init -q
}

teardown() {
  rm -rf "$TEMP_DIR"
}

@test "env: env.sh --help shows usage" {
  run sh scripts/env.sh --help
  assert_success
  assert_output --partial "Manages environment configuration files"
}

@test "env: env.sh setup creates .env from .env.example" {
  cd "$TEMP_DIR" || exit
  echo "TEST_VAR=true" >.env.example
  run sh scripts/env.sh setup
  assert_success
  assert [ -f ".env" ]
  run grep "TEST_VAR=true" .env
  assert_success
}

@test "env: env.sh check validates .env against .env.example" {
  cd "$TEMP_DIR" || exit
  echo "REQUIRED_VAR=true" >.env.example
  touch .env
  run sh scripts/env.sh check
  assert_failure
  assert_output --partial "Missing key: REQUIRED_VAR"
}

@test "env: env.sh respects project root guard" {
  mkdir nested && cd nested || exit
  run sh ../scripts/env.sh --help
  assert_failure
  assert_output --partial "Error: This script must be run from the project root."
}
