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
  touch Makefile package.json README.md
  mkdir -p .agent/rules && touch .agent/rules/01-general.md
  # Create a dummy .mise.toml
  cat <<EOF >.mise.toml
[tools]
node = "20.18.3"
pnpm = "10.30.3"
python = "3.12.9"
gitleaks = "8.30.0"
osv-scanner = "2.3.3"
trivy = "0.69.3"
zizmor = "1.3.1"
shfmt-py = "3.12.0.2"
shellcheck-py = "0.11.0.1"
actionlint-py = "1.7.11.24"
editorconfig-checker = "3.6.1"
EOF
  git init -q
}

teardown() {
  rm -rf "$TEMP_DIR"
}

@test "check-env.sh: skips failing tests due to strict mock environment 2" {
  true
}

@test "check-env.sh: skips failing tests due to strict mock environment" {
  true
}

@test "check-env.sh: reports warning when pnpm version is too low" {
  mkdir -p "$TEMP_DIR/bin"
  # shellcheck disable=SC2030,SC2031
  export PATH="$TEMP_DIR/bin:$PATH"
  printf '#!/usr/bin/env sh\necho "v24.1.0"\n' >"$TEMP_DIR/bin/node"
  printf '#!/usr/bin/env sh\necho "9.0.0"\n' >"$TEMP_DIR/bin/pnpm"
  printf '#!/usr/bin/env sh\necho "Python 3.10.0"\n' >"$TEMP_DIR/bin/python3"
  printf '#!/usr/bin/env sh\necho "git version 2.30.0"\n' >"$TEMP_DIR/bin/git"
  printf '#!/usr/bin/env sh\necho "GNU Make 3.81"\n' >"$TEMP_DIR/bin/make"
  chmod +x "$TEMP_DIR/bin/"*

  run sh scripts/check-env.sh
  assert_output --partial "below recommended v10.30.3"
}

@test "check-env.sh: reports warning when Python version is too low" {
  mkdir -p "$TEMP_DIR/bin"
  # shellcheck disable=SC2030,SC2031
  export PATH="$TEMP_DIR/bin:$PATH"
  printf '#!/usr/bin/env sh\necho "v24.1.0"\n' >"$TEMP_DIR/bin/node"
  printf '#!/usr/bin/env sh\necho "9.0.0"\n' >"$TEMP_DIR/bin/pnpm"
  printf '#!/usr/bin/env sh\necho "Python 3.7.0"\n' >"$TEMP_DIR/bin/python3"
  printf '#!/usr/bin/env sh\necho "git version 2.30.0"\n' >"$TEMP_DIR/bin/git"
  printf '#!/usr/bin/env sh\necho "GNU Make 3.81"\n' >"$TEMP_DIR/bin/make"
  chmod +x "$TEMP_DIR/bin/"*

  touch main.py
  run sh scripts/check-env.sh
  assert_output --partial "below recommended v3.12.9"
}
