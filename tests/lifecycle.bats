#!/usr/bin/env bats

setup() {
  load '../vendor/bats-support/load.bash'
  load '../vendor/bats-assert/load.bash'

  # Create a temporary workspace
  export TEMP_DIR
  unset _SNOWDREAM_TOP_LEVEL_SCRIPT
  TEMP_DIR="$(mktemp -d)"
  cp -r scripts "$TEMP_DIR/"

  # Create a dummy project structure
  cd "$TEMP_DIR" || exit
  touch Makefile LICENSE README.md
  mkdir -p .agent/rules && touch .agent/rules/01-general.md
  echo '{"name":"test-project"}' >package.json
  git init -q

  # Mock content for init-project.sh
  echo "This is template by snowdreamtech (snowdream)" >README.md
  echo "Copyright (c) 2023-present SnowdreamTech Inc." >LICENSE
}

teardown() {
  rm -rf "$TEMP_DIR"
}

# --- install.sh tests ---

@test "lifecycle: install.sh dry-run reports planned installations" {
  run sh scripts/install.sh --dry-run
  assert_success
  assert_output --partial "Running in DRY-RUN mode"
  assert_output --partial "Installing Project Dependencies"
}

@test "lifecycle: install.sh respects project root guard" {
  mkdir nested && cd nested || exit
  run sh ../scripts/install.sh
  assert_failure
  assert_output --partial "Error: This script must be run from the project root."
}

# --- setup.sh tests ---

@test "lifecycle: setup.sh dry-run reports planned tool setups" {
  run sh scripts/setup.sh --dry-run
  assert_success
  assert_output --partial "Running in DRY-RUN mode"
  # Support both fresh setup and pre-detected tools
  run bash -c "sh scripts/setup.sh --dry-run | grep -E 'Setting up Node.js|✅ Detected.*Node.js'"
  assert_success
  run bash -c "sh scripts/setup.sh --dry-run | grep -E 'Setting up Python|✅ Detected.*Python'"
  assert_success
  run bash -c "sh scripts/setup.sh --dry-run | grep -E 'Setting up Pre-commit Hooks|✅ Detected.*Git Hooks'"
  assert_success
}

# --- init-project.sh tests ---

@test "lifecycle: init-project.sh aborts on 'N' confirmation" {
  # Provide flags and NO confirmation via pipe
  run bash -c "export SNOWDREAM_TEST_FORCE_CONFIRM=1 && yes n | sh scripts/init-project.sh --project=dummy-app --author='Jane Doe' --github=janeorg"
  assert_failure
  assert_output --partial "Aborted."

  run cat README.md
  assert_output "This is template by snowdreamtech (snowdream)"
}

@test "lifecycle: init-project.sh replaces placeholders correctly on 'Y'" {
  # Provide flags and YES confirmation via --yes, NO git reinit via pipe
  run bash -c "yes n | sh scripts/init-project.sh --project=dummy-app --author='Jane Doe' --github=janeorg --yes"
  assert_success
  assert_output --partial "Project Hydration Complete!"

  run cat README.md
  assert_output "This is dummy-app by janeorg (janeorg)"

  CURRENT_YEAR=$(date +%Y)
  run cat LICENSE
  assert_output "Copyright (c) $CURRENT_YEAR-present Jane Doe"
}
