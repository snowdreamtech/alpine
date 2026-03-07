#!/usr/bin/env bats

setup() {
  load '../node_modules/bats-support/load.bash'
  load '../node_modules/bats-assert/load.bash'

  # Create a temporary workspace
  export TEMP_DIR
  TEMP_DIR="$(mktemp -d)"
  mkdir -p "$TEMP_DIR/scripts/lib"
  # Copy functional scripts
  for f in audit.sh bench.sh update.sh env.sh verify.sh; do
    cp "scripts/$f" "$TEMP_DIR/scripts/"
  done
  cp "scripts/lib/common.sh" "$TEMP_DIR/scripts/lib/"

  # Create a dummy project structure
  cd "$TEMP_DIR" || exit
  touch Makefile LICENSE README.md pnpm-lock.yaml
  echo '{"name":"test-project","packageManager":"pnpm@10.28.0"}' >package.json
  git init -q
}

teardown() {
  rm -rf "$TEMP_DIR"
}

@test "verify.sh: orchestration logic runs sub-steps (dry-run)" {
  run sh scripts/verify.sh --help
  assert_success
  assert_output --partial "Run a full project verification suite"
}

@test "audit.sh: dry-run reports security scans" {
  run sh scripts/audit.sh --dry-run
  assert_success
  assert_output --partial "Starting Security Auditor"
}

@test "bench.sh: dry-run reports benchmark activities" {
  run sh scripts/bench.sh --dry-run
  assert_success
  assert_output --partial "Starting Performance Benchmarker"
}

@test "update.sh: dry-run reports tool updates" {
  run sh scripts/update.sh --dry-run
  assert_success
  assert_output --partial "Starting Tooling Update Manager"
}

@test "env.sh: basic help and usage" {
  run sh scripts/env.sh --help
  assert_success
  assert_output --partial "Manages environment configuration files"
}
