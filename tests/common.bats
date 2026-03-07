#!/usr/bin/env bats

setup() {
  load '../node_modules/bats-support/load.bash'
  load '../node_modules/bats-assert/load.bash'

  # Create a temporary workspace
  export TEMP_DIR
  TEMP_DIR="$(mktemp -d)"
  mkdir -p "$TEMP_DIR/scripts/lib"
  cp "scripts/lib/common.sh" "$TEMP_DIR/scripts/lib/"

  # Create a dummy script that sources common.sh
  cat <<EOF >"$TEMP_DIR/test_script.sh"
#!/bin/sh
SCRIPT_DIR=\$(cd "\$(dirname "\$0")" && pwd)
. "\$SCRIPT_DIR/scripts/lib/common.sh"

case "\$1" in
  guard) guard_project_root ;;
  log) log_info "test info"; log_success "test success"; log_warn "test warn"; log_error "test error" ;;
  args) parse_common_args "\$@"; echo "VERBOSE=\$VERBOSE"; echo "DRY_RUN=\$DRY_RUN" ;;
esac
EOF
  chmod +x "$TEMP_DIR/test_script.sh"
}

teardown() {
  rm -rf "$TEMP_DIR"
}

@test "common.sh: guard_project_root fails outside project root" {
  cd "$TEMP_DIR" || exit
  run sh test_script.sh guard
  assert_failure
  assert_output --partial "Error: This script must be run from the project root."
}

@test "common.sh: guard_project_root passes in project root (with Makefile and .git)" {
  cd "$TEMP_DIR" || exit
  touch Makefile
  mkdir .git
  run sh test_script.sh guard
  assert_success
}

@test "common.sh: parse_common_args handles --dry-run" {
  run sh "$TEMP_DIR/test_script.sh" args --dry-run
  assert_success
  assert_line --partial "DRY_RUN=1"
  assert_line --partial "Running in DRY-RUN mode"
}

@test "common.sh: parse_common_args handles -v and -q" {
  run sh "$TEMP_DIR/test_script.sh" args -v
  assert_line "VERBOSE=2"

  run sh "$TEMP_DIR/test_script.sh" args -q
  assert_line "VERBOSE=0"
}

@test "common.sh: logging functions produce colored output" {
  # We check for ANSI escape sequences (\033 or \x1b)
  run sh "$TEMP_DIR/test_script.sh" log
  assert_success
  # Check if output contains ESC[ (color start). bats-assert output handles escape codes.
  # We check for the specific literal strings we defined in common.sh
  assert_line --partial "test info"
  assert_line --partial "test success"
  assert_line --partial "test error"
}
