#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# scripts/init-project.sh - Project Branding Hydrator
#
# Purpose:
#   Customizes the template for a new project by replacing branded placeholders.
#   Streamlines project onboarding with safe, global metadata injection.
#
# Usage:
#   sh scripts/init-project.sh [OPTIONS]
#
# Standards:
#   - POSIX-compliant sh logic.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 03 (Architecture).
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Safe placeholder replacement across the entire codebase.
#   - Integrated Git re-initialization and remote cleanup.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# Purpose: Main entry point for project hydration.
#          Collects project metadata and performs global placeholder replacement.
# Params:
#   $@ - Command line arguments (--project, --author, --github, -y)
# Examples:
#   sh scripts/init-project.sh --project=my-app --author="John Doe" --github=myorg -y
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  local _PROJECT_NAME_HYD=""
  local _AUTHOR_NAME_HYD=""
  local _GITHUB_ORG_HYD=""
  local _AUTO_CON_HYD=0
  local _STACK_HYD=""

  parse_common_args "$@"

  local _arg_hyd
  for _arg_hyd in "$@"; do
    case "$_arg_hyd" in
    --project=*) _PROJECT_NAME_HYD="${_arg_hyd#*=}" ;;
    --author=*) _AUTHOR_NAME_HYD="${_arg_hyd#*=}" ;;
    --github=*) _GITHUB_ORG_HYD="${_arg_hyd#*=}" ;;
    --stack=*) _STACK_HYD="${_arg_hyd#*=}" ;;
    -y | --yes) _AUTO_CON_HYD=1 ;;
    esac
  done

  # Check if we are running in a terminal
  local _IS_TTY_HYD=0
  [ -t 0 ] && _IS_TTY_HYD=1

  if [ "${VERBOSE:-0}" -ge 1 ]; then
    printf "%b💧 Project Hydration: Converting Template to Project...%b\n\n" "${BLUE}" "${NC}"
  fi

  # 3. Input Collection (Interactive fallback or validation)
  if [ -z "$_PROJECT_NAME_HYD" ]; then
    if [ "${_IS_TTY_HYD:-0}" -eq 1 ] && [ "${_AUTO_CON_HYD:-0}" -eq 0 ]; then
      printf "Enter Project Name (e.g., my-awesome-app): "
      read -r _PROJECT_NAME_HYD
    else
      log_error "Error: --project is required in non-interactive mode."
      exit 1
    fi
  fi

  if [ -z "$_AUTHOR_NAME_HYD" ]; then
    if [ "${_IS_TTY_HYD:-0}" -eq 1 ] && [ "${_AUTO_CON_HYD:-0}" -eq 0 ]; then
      printf "Enter Author Name (e.g., John Doe): "
      read -r _AUTHOR_NAME_HYD
    else
      log_error "Error: --author is required in non-interactive mode."
      exit 1
    fi
  fi

  if [ -z "$_GITHUB_ORG_HYD" ]; then
    if [ "${_IS_TTY_HYD:-0}" -eq 1 ] && [ "${_AUTO_CON_HYD:-0}" -eq 0 ]; then
      printf "Enter GitHub Username/Org (e.g., myorg): "
      read -r _GITHUB_ORG_HYD
    else
      log_error "Error: --github is required in non-interactive mode."
      exit 1
    fi
  fi

  local _OLD_PROJ_REF="template"
  local _OLD_ORG_REF="snowdreamtech"
  local _OLD_USER_REF="snowdream"

  # 4. Confirmation
  if [ "${VERBOSE:-0}" -ge 1 ]; then
    printf "\n%bConfiguration Summary:%b\n" "${YELLOW}" "${NC}"
    printf "  Project: %b%s%b\n" "${GREEN}" "$_PROJECT_NAME_HYD" "${NC}"
    printf "  Author:  %b%s%b\n" "${GREEN}" "$_AUTHOR_NAME_HYD" "${NC}"
    printf "  GitHub:  %b%s%b\n" "${GREEN}" "$_GITHUB_ORG_HYD" "${NC}"
  fi

  if [ "${DRY_RUN:-0}" -eq 0 ] && [ "${VERBOSE:-0}" -ge 1 ] && [ "${_AUTO_CON_HYD:-0}" -eq 0 ]; then
    if [ "${_IS_TTY_HYD:-0}" -eq 1 ] || [ "${SNOWDREAM_TEST_FORCE_CONFIRM:-0}" = "1" ]; then
      printf "\nProceed with hydration? (y/N): "
      local _CONFIRM_HYD
      read -r _CONFIRM_HYD
      case "$_CONFIRM_HYD" in
      [yY]*) ;;
      *)
        log_error "Aborted."
        exit 1
        ;;
      esac
    else
      log_info "Non-interactive mode: Proceeding automatically..."
    fi
  fi

  # 5. Replace Placeholders
  log_info "\nStep 1: Replacing placeholders in files..."

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_warn "DRY-RUN: Would replace '$_OLD_PROJ_REF' with '$_PROJECT_NAME_HYD' and '$_OLD_ORG_REF/$_OLD_USER_REF' with '$_GITHUB_ORG_HYD' in matching files."
  else
    # Use perl for cross-platform compatibility
    find . -type f \
      ! -path "*/.git/*" \
      ! -path "./node_modules/*" \
      ! -path "./.venv/*" \
      ! -path "./scripts/init-project.sh" \
      -exec perl -pi -e "s~$_OLD_PROJ_REF~$_PROJECT_NAME_HYD~g" {} +

    find . -type f \
      ! -path "*/.git/*" \
      ! -path "./node_modules/*" \
      ! -path "./.venv/*" \
      ! -path "./scripts/init-project.sh" \
      ! -path "./scripts/init-project.ps1" \
      ! -path "./scripts/init-project.bat" \
      -exec perl -pi -e "s~$_OLD_ORG_REF|$_OLD_USER_REF~$_GITHUB_ORG_HYD~g" {} +
  fi

  # 6. Update LICENSE
  log_info "Step 2: Updating LICENSE..."
  local _CUR_YEAR_HYD
  _CUR_YEAR_HYD=$(date +%Y)
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_warn "DRY-RUN: Would update LICENSE copyright to $_CUR_YEAR_HYD and $_AUTHOR_NAME_HYD."
  else
    perl -pi -e "s~Copyright \(c\) \d{4}-present SnowdreamTech Inc\.~Copyright (c) $_CUR_YEAR_HYD-present $_AUTHOR_NAME_HYD~g" LICENSE
  fi

  # 7. Git Initialization
  if [ "${DRY_RUN:-0}" -eq 0 ] && [ "${VERBOSE:-0}" -ge 1 ]; then
    printf "\nRe-initialize Git repository? (y/N): "
    local _REINIT_GIT_HYD
    read -r _REINIT_GIT_HYD
    case "$_REINIT_GIT_HYD" in
    [yY]*)
      log_info "Step 3: Re-initializing Git..."
      rm -rf .git
      git init
      git add .
      git commit -m "initial commit: project hydrated from template"
      ;;
    *) ;;
    esac
  elif [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_warn "DRY-RUN: Would prompt for Git re-initialization."
  fi

  # 8. Scaffolding (Optional)
  if [ -n "$_STACK_HYD" ]; then
    log_info "\nStep 4: Creating $_STACK_HYD scaffolding..."
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
      log_warn "DRY-RUN: Would create source and tests for $_STACK_HYD."
    else
      case "$_STACK_HYD" in
      python)
        mkdir -p src tests
        [ ! -f src/main.py ] && printf 'def main():\n    print("Hello, World!")\n\nif __name__ == "__main__":\n    main()\n' >src/main.py
        [ ! -f tests/test_main.py ] && printf 'def test_main():\n    assert True\n' >tests/test_main.py
        ;;
      node)
        mkdir -p src tests
        [ ! -f src/index.js ] && printf 'console.log("Hello, World!");\n' >src/index.js
        [ ! -f tests/index.test.js ] && printf 'test("basic", () => { expect(true).toBe(true); });\n' >tests/index.test.js
        ;;
      go)
        mkdir -p src tests
        [ ! -f src/main.go ] && printf 'package main\n\nimport "fmt"\n\nfunc main() {\n    fmt.Println("Hello, World!")\n}\n' >src/main.go
        [ ! -f tests/main_test.go ] && printf 'package main\n\nimport "testing"\n\nfunc TestMain(t *testing.T) {\n    // test logic\n}\n' >tests/main_test.go
        ;;
      java)
        mkdir -p src/main/java/com/example src/test/java/com/example
        [ ! -f src/main/java/com/example/Main.java ] && printf 'package com.example;\n\npublic class Main {\n    public static void main(String[] args) {\n        System.out.println("Hello, World!");\n    }\n}\n' >src/main/java/com/example/Main.java
        [ ! -f src/test/java/com/example/MainTest.java ] && printf 'package com.example;\n\nimport org.junit.jupiter.api.Test;\nimport static org.junit.jupiter.api.Assertions.assertTrue;\n\nclass MainTest {\n    @Test\n    void contextLoads() {\n        assertTrue(true);\n    }\n}\n' >src/test/java/com/example/MainTest.java
        ;;
      php)
        mkdir -p src tests
        [ ! -f src/index.php ] && printf '<?php\n\necho "Hello, World!";\n' >src/index.php
        # shellcheck disable=SC2016
        [ ! -f tests/IndexTest.php ] && printf '<?php\n\nuse PHPUnit\\Framework\\TestCase;\n\nclass IndexTest extends TestCase {\n    public function testBasic() {\n        $this->assertTrue(true);\n    }\n}\n' >tests/IndexTest.php
        ;;
      rust)
        mkdir -p src tests
        [ ! -f src/main.rs ] && printf 'fn main() {\n    println!("Hello, World!");\n}\n' >src/main.rs
        [ ! -f tests/main_test.rs ] && printf '#[test]\nfn test_basic() {\n    assert!(true);\n}\n' >tests/test_main.rs
        ;;
      ruby)
        mkdir -p lib spec
        # shellcheck disable=SC2016
        [ ! -f lib/main.rb ] && printf 'def main\n  puts "Hello, World!"\nend\n\nmain if __FILE__ == $0\n' >lib/main.rb
        [ ! -f spec/main_spec.rb ] && printf 'RSpec.describe "Main" do\n  it "works" do\n    expect(true).to be true\n  end\nend\n' >spec/main_spec.rb
        ;;
      dotnet)
        mkdir -p src tests
        [ ! -f src/Program.cs ] && printf 'using System;\n\nnamespace MyProject {\n    class Program {\n        static void Main(string[] args) {\n            Console.WriteLine("Hello, World!");\n        }\n    }\n}\n' >src/Program.cs
        [ ! -f tests/UnitTest1.cs ] && printf 'using Xunit;\n\nnamespace MyProject.Tests {\n    public class UnitTest1 {\n        [Fact]\n        public void Test1() {\n            Assert.True(true);\n        }\n    }\n}\n' >tests/UnitTest1.cs
        ;;
      *)
        log_warn "Unknown stack: $_STACK_HYD. Skipping scaffolding."
        ;;
      esac
    fi
  fi

  log_success "\n🚀 Project Hydration Complete!"

  # 9. Standardized Next Actions
  if [ "${DRY_RUN:-0}" -eq 0 ] && [ "$_IS_TOP_LEVEL" = "true" ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bmake setup%b to initialize your development environment.\n" "${GREEN}" "${NC}"
    printf "  - Run %bmake install%b to install all project dependencies.\n" "${GREEN}" "${NC}"
    printf "  - Run %bmake verify%b to validate the project state.\n" "${GREEN}" "${NC}"
  fi
}

main "$@"
