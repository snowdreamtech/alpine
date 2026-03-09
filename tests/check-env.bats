#!/usr/bin/env bats

setup() {
  load '../node_modules/bats-support/load.bash'
  load '../node_modules/bats-assert/load.bash'

  # Create a temporary workspace
  export TEMP_DIR
  TEMP_DIR="$(mktemp -d)"
  mkdir -p "$TEMP_DIR/scripts/lib"
  cp "scripts/check-env.sh" "$TEMP_DIR/scripts/"
  cp "scripts/lib/common.sh" "$TEMP_DIR/scripts/lib/"

  # Create a dummy project structure
  cd "$TEMP_DIR" || exit
  touch Makefile package.json README.md
  mkdir -p .agent/rules && touch .agent/rules/01-general.md
  git init -q
}

teardown() {
  rm -rf "$TEMP_DIR"
}

@test "check-env.sh: reports success when all tools and files are present" {
  # Mock tools by putting them in PATH
  mkdir -p "$TEMP_DIR/bin"
  # shellcheck disable=SC2030,SC2031
  export PATH="$TEMP_DIR/bin:$PATH"

  cat <<EOF >"$TEMP_DIR/bin/node"
#!/bin/sh
echo "v24.1.0"
EOF
  cat <<EOF >"$TEMP_DIR/bin/pnpm"
#!/bin/sh
echo "9.0.0"
EOF
  cat <<EOF >"$TEMP_DIR/bin/python3"
#!/bin/sh
echo "Python 3.10.0"
EOF
  cat <<EOF >"$TEMP_DIR/bin/git"
#!/bin/sh
echo "git version 2.30.0"
EOF
  cat <<EOF >"$TEMP_DIR/bin/make"
#!/bin/sh
echo "GNU Make 3.81"
EOF
  cat <<EOF >"$TEMP_DIR/bin/go"
#!/bin/sh
echo "go version go1.21.0 darwin/arm64"
EOF
  cat <<EOF >"$TEMP_DIR/bin/ruby"
#!/bin/sh
echo "ruby 3.2.2 (2023-03-30 revision e51014f9c0) [arm64-darwin22]"
EOF
  chmod +x "$TEMP_DIR/bin/"*

  # Create files to trigger language checks
  touch go.mod main.py Gemfile

  run sh scripts/check-env.sh
  assert_success
  assert_output --partial "Environment is HEALTHY"
  assert_output --partial "Go: v1.21.0"
  assert_output --partial "Python: v3.10.0"
  assert_output --partial "Ruby: v3.2.2"
}

@test "check-env.sh: reports failure when a non-guard critical file is missing" {
  # Mock tools (healthy)
  mkdir -p "$TEMP_DIR/bin"
  # shellcheck disable=SC2030,SC2031
  export PATH="$TEMP_DIR/bin:$PATH"
  printf '#!/bin/sh\necho "v24.1.0"' >"$TEMP_DIR/bin/node"
  printf '#!/bin/sh\necho "9.0.0"' >"$TEMP_DIR/bin/pnpm"
  printf '#!/bin/sh\necho "Python 3.10.0"' >"$TEMP_DIR/bin/python3"
  printf '#!/bin/sh\necho "git version 2.30.0"' >"$TEMP_DIR/bin/git"
  printf '#!/bin/sh\necho "GNU Make 3.81"' >"$TEMP_DIR/bin/make"
  chmod +x "$TEMP_DIR/bin/"*

  # Remove critical file (README.md is NOT a guard file in common.sh)
  # Guard files in common.sh are Makefile and .git
  rm README.md

  run sh scripts/check-env.sh
  assert_failure
  assert_output --partial "Missing critical file: README.md"
}

@test "check-env.sh: reports warning/failure when tool version is too low" {
  mkdir -p "$TEMP_DIR/bin"
  # shellcheck disable=SC2030,SC2031
  export PATH="$TEMP_DIR/bin:$PATH"

  # Node version too low
  printf '#!/bin/sh\necho "v18.0.0"' >"$TEMP_DIR/bin/node"
  # Other tools ok
  printf '#!/bin/sh\necho "9.0.0"' >"$TEMP_DIR/bin/pnpm"
  printf '#!/bin/sh\necho "Python 3.10.0"' >"$TEMP_DIR/bin/python3"
  printf '#!/bin/sh\necho "git version 2.30.0"' >"$TEMP_DIR/bin/git"
  printf '#!/bin/sh\necho "GNU Make 3.81"' >"$TEMP_DIR/bin/make"
  chmod +x "$TEMP_DIR/bin/"*

  touch main.py
  touch main.py
  run sh scripts/check-env.sh
  assert_failure
  assert_output --partial "Node.js: v18.0.0 (below recommended v24.1.0)"
}
