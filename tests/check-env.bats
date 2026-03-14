#!/usr/bin/env bats

setup() {
  load '../vendor/bats-support/load.bash'
  load '../vendor/bats-assert/load.bash'

  # Create a temporary workspace
  export TEMP_DIR
  unset _SNOWDREAM_TOP_LEVEL_SCRIPT
  TEMP_DIR="$(mktemp -d)"
  mkdir -p "$TEMP_DIR/scripts/lib"
  cp "scripts/check-env.sh" "$TEMP_DIR/scripts/"
  cp "scripts/lib/common.sh" "$TEMP_DIR/scripts/lib/"

  # Create a dummy project structure
  cd "$TEMP_DIR" || exit
  touch Makefile package.json README.md
  mkdir -p .agent/rules && touch .agent/rules/01-general.md
  # Create a dummy .mise.toml
  cat <<EOF >.mise.toml
[tools]
node = "20.18.3"
pnpm = "9.0.0"
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
echo "Python 3.12.9"
EOF
  cat <<EOF >"$TEMP_DIR/bin/git"
#!/bin/sh
echo "git version 2.30.0"
EOF
  cat <<EOF >"$TEMP_DIR/bin/mise"
#!/bin/sh
if [ "\$1" = "ls" ]; then
  echo "{}"
else
  echo "2026.3.8"
fi
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
  cat <<EOF >"$TEMP_DIR/bin/java"
#!/bin/sh
echo "openjdk version \"17.0.8\" 2023-07-18"
EOF
  cat <<EOF >"$TEMP_DIR/bin/php"
#!/bin/sh
echo "PHP 8.2.10 (cli) (built: Aug 31 2023 15:52:53) (NTS)"
EOF
  cat <<EOF >"$TEMP_DIR/bin/dotnet"
#!/bin/sh
echo "7.0.401"
EOF
  cat <<EOF >"$TEMP_DIR/bin/cargo"
#!/bin/sh
echo "cargo 1.72.1 (103487372 2023-09-19)"
EOF
  cat <<EOF >"$TEMP_DIR/bin/swift"
#!/bin/sh
echo "Apple Swift version 5.9 (swiftlang-5.9.0.128.108 clang-1500.0.40.1)"
EOF
  cat <<EOF >"$TEMP_DIR/bin/kotlin"
#!/bin/sh
echo "Kotlin version 1.9.10-release-445 (JRE 17.0.8+7)"
EOF
  cat <<EOF >"$TEMP_DIR/bin/dart"
#!/bin/sh
echo "Dart SDK version: 3.1.2 (stable) (Tue Sep 12 14:43:30 2023 +0000) on \"macos_arm64\""
EOF
  cat <<EOF >"$TEMP_DIR/bin/gitleaks"
#!/bin/sh
echo "v8.30.0"
EOF
  cat <<EOF >"$TEMP_DIR/bin/osv-scanner"
#!/bin/sh
echo "v2.3.3"
EOF
  cat <<EOF >"$TEMP_DIR/bin/trivy"
#!/bin/sh
echo "v0.69.3"
EOF
  cat <<EOF >"$TEMP_DIR/bin/golangci-lint"
#!/bin/sh
echo "1.55.0"
EOF
  cat <<EOF >"$TEMP_DIR/bin/zizmor"
#!/bin/sh
echo "v1.3.1"
EOF
  cat <<EOF >"$TEMP_DIR/bin/shellcheck"
#!/bin/sh
echo "0.11.0.1"
EOF
  cat <<EOF >"$TEMP_DIR/bin/shfmt"
#!/bin/sh
echo "3.12.0.2"
EOF
  cat <<EOF >"$TEMP_DIR/bin/actionlint"
#!/bin/sh
echo "1.7.11.24"
EOF
  cat <<EOF >"$TEMP_DIR/bin/editorconfig-checker"
#!/bin/sh
echo "3.6.1"
EOF
  chmod +x "$TEMP_DIR/bin/"*

  # Create files to trigger language checks
  touch go.mod main.py Gemfile pom.xml composer.json global.json Cargo.toml Package.swift build.gradle.kts pubspec.yaml

  run sh scripts/check-env.sh
  assert_success
  assert_output --partial "Environment is HEALTHY"
  assert_output --partial "Go: v1.21.0"
  assert_output --partial "Python: v3.12.9"
  assert_output --partial "Ruby: v3.2.2"
  assert_output --partial "Java: v17.0.8"
  assert_output --partial "PHP: v8.2.10"
  assert_output --partial ".NET: v7.0.401"
  assert_output --partial "Rust: v1.72.1"
  assert_output --partial "── Mobile Support ──"
  assert_output --partial "Swift: v5.9"
  assert_output --partial "Kotlin: v1.9.10"
  assert_output --partial "Dart: v3.1.2"
  assert_output --partial "Gitleaks: v8.30.0"
  assert_output --partial "OSV-scanner: v2.3.3"
  assert_output --partial "Trivy: v0.69.3"
  assert_output --partial "Zizmor: v1.3.1"
  assert_output --partial "golangci-lint: v1.55.0"
  assert_output --partial "Actionlint: v1.7.11.24"
  assert_output --partial "EditorConfig: v3.6.1"
}

@test "check-env.sh: reports failure when a non-guard critical file is missing" {
  # Mock tools (healthy)
  mkdir -p "$TEMP_DIR/bin"
  # shellcheck disable=SC2030,SC2031
  export PATH="$TEMP_DIR/bin:$PATH"
  printf '#!/bin/sh\necho "v24.1.0"\n' >"$TEMP_DIR/bin/node"
  printf '#!/bin/sh\necho "9.0.0"\n' >"$TEMP_DIR/bin/pnpm"
  printf '#!/bin/sh\necho "Python 3.10.0"\n' >"$TEMP_DIR/bin/python3"
  printf '#!/bin/sh\necho "git version 2.30.0"\n' >"$TEMP_DIR/bin/git"
  printf '#!/bin/sh\necho "GNU Make 3.81"\n' >"$TEMP_DIR/bin/make"
  chmod +x "$TEMP_DIR/bin/"*

  # Remove critical file (README.md is NOT a guard file in common.sh)
  # Guard files in common.sh are Makefile and .git
  rm README.md

  run sh scripts/check-env.sh
  assert_failure
  assert_output --partial "Missing critical file: README.md"
}

@test "check-env.sh: reports warning when pnpm version is too low" {
  mkdir -p "$TEMP_DIR/bin"
  # shellcheck disable=SC2030,SC2031
  export PATH="$TEMP_DIR/bin:$PATH"
  printf '#!/bin/sh\necho "v24.1.0"\n' >"$TEMP_DIR/bin/node"
  printf '#!/bin/sh\necho "8.0.0"\n' >"$TEMP_DIR/bin/pnpm"
  printf '#!/bin/sh\necho "Python 3.10.0"\n' >"$TEMP_DIR/bin/python3"
  printf '#!/bin/sh\necho "git version 2.30.0"\n' >"$TEMP_DIR/bin/git"
  printf '#!/bin/sh\necho "GNU Make 3.81"\n' >"$TEMP_DIR/bin/make"
  chmod +x "$TEMP_DIR/bin/"*

  run sh scripts/check-env.sh
  assert_failure
  assert_output --partial "pnpm: v8.0.0 (below recommended v9.0.0)"
}

@test "check-env.sh: reports warning when Python version is too low" {
  mkdir -p "$TEMP_DIR/bin"
  # shellcheck disable=SC2030,SC2031
  export PATH="$TEMP_DIR/bin:$PATH"
  printf '#!/bin/sh\necho "v24.1.0"\n' >"$TEMP_DIR/bin/node"
  printf '#!/bin/sh\necho "9.0.0"\n' >"$TEMP_DIR/bin/pnpm"
  printf '#!/bin/sh\necho "Python 3.7.0"\n' >"$TEMP_DIR/bin/python3"
  printf '#!/bin/sh\necho "git version 2.30.0"\n' >"$TEMP_DIR/bin/git"
  printf '#!/bin/sh\necho "GNU Make 3.81"\n' >"$TEMP_DIR/bin/make"
  chmod +x "$TEMP_DIR/bin/"*

  touch main.py
  run sh scripts/check-env.sh
  assert_output --partial "Python: v3.7.0 (below recommended v3.12.9)"
}
