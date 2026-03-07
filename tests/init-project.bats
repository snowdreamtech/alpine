#!/usr/bin/env bats

setup() {
  load '../node_modules/bats-support/load.bash'
  load '../node_modules/bats-assert/load.bash'

  # Create a safe workspace to prevent modifying actual project files
  # Use mktemp -d with a portable template
  export TEMP_DIR
  TEMP_DIR="$(mktemp -d)"

  # Create dummy files to test replacements
  echo "This is template by snowdreamtech (snowdream)" >"$TEMP_DIR/README.md"
  echo "Copyright (c) 2023-present SnowdreamTech Inc." >"$TEMP_DIR/LICENSE"

  # Copy the script and common library to test workspace
  mkdir -p "$TEMP_DIR/scripts/lib"
  cp "$BATS_TEST_DIRNAME/../scripts/init-project.sh" "$TEMP_DIR/scripts/"
  cp "$BATS_TEST_DIRNAME/../scripts/lib/common.sh" "$TEMP_DIR/scripts/lib/"
  chmod +x "$TEMP_DIR/scripts/init-project.sh"
}

teardown() {
  rm -rf "$TEMP_DIR"
}

@test "Hydration script aborts on 'N' confirmation" {
  cd "$TEMP_DIR"

  # Provide inputs: project, author, org, NO confirmation
  run bash -c "echo -e 'dummy-app\nJane Doe\njaneorg\nn\n' | ./scripts/init-project.sh"

  assert_failure
  assert_output --partial "Aborted."

  # Ensure no replacements happened
  run cat README.md
  assert_output "This is template by snowdreamtech (snowdream)"
}

@test "Hydration script replaces placeholders correctly on 'Y'" {
  cd "$TEMP_DIR"

  # Provide inputs: project, author, org, YES confirmation, NO git reinit
  run bash -c "echo -e 'dummy-app\nJane Doe\njaneorg\ny\nn\n' | ./scripts/init-project.sh"

  assert_success
  assert_output --partial "Project Hydration Complete!"

  # Check text replacements
  run cat README.md
  assert_output "This is dummy-app by janeorg (janeorg)"

  # Check LICENSE year and author replacement
  CURRENT_YEAR=$(date +%Y)
  run cat LICENSE
  assert_output "Copyright (c) $CURRENT_YEAR-present Jane Doe"
}
