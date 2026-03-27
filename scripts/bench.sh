#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# scripts/bench.sh - Performance Benchmarking Suite
#
# Purpose:
#   Standard entrance for performance measurements and regression testing.
#   Orchestrates benchmarks for Go, Node.js, and Python targeting high performance.
#
# Usage:
#   sh scripts/bench.sh [OPTIONS] [SUITE]
#
# Standards:
#   - POSIX-compliant sh logic.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General, Network), Rule 06 (CI/Testing).
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Automated discovery of language-specific benchmarking tools.
#   - Modular execution for multiple language stacks.

set -eu

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "${0:-}")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# ── Functions ────────────────────────────────────────────────────────────────

# Purpose: Displays usage information for the benchmarking suite.
# Examples:
#   show_help
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS] [SUITE]

Runs performance benchmarks for the project.

Options:
  -q, --quiet      Suppress informational output.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

Suites (default: all):
  python           Run pytest-benchmark suites
  node             Run vitest/benchmark suites
  all              Run all detected benchmarks

EOF
}

# Purpose: Executes Python-specific performance benchmarks using pytest-benchmark.
#          Scans for files containing "benchmark" and runs pytest --benchmark-only.
# Examples:
#   run_python_bench
run_python_bench() {
  if find . -maxdepth 2 -name "*benchmark*" | grep -q .; then
    log_info "── Testing Python Benchmarks (pytest-benchmark) ──"
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
      log_success "DRY-RUN: Would run pytest-benchmark"
    elif [ -x "$VENV/bin/pytest" ]; then
      "$VENV/bin/pytest" --benchmark-only
    else
      log_warn "pytest-benchmark not found. Skipping."
    fi
  fi
}

# Purpose: Executes Node.js-specific performance benchmarks.
#          Runs the 'bench' script defined in package.json.
# Examples:
#   run_node_bench
run_node_bench() {
  run_npm_script "bench"
}

# Purpose: Main entry point for the performance benchmarking suite.
# Params:
#   $@ - Command line arguments and optional suite selection
# Examples:
#   main --verbose node
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  local _SUITE_BCH="all"
  local _arg_bch
  for _arg_bch in "$@"; do
    case "${_arg_bch:-}" in
    python | node | all) _SUITE_BCH="${_arg_bch:-}" ;;
    esac
  done
  parse_common_args "$@"

  log_info "⚡ Starting Performance Benchmarker...\n"

  case "${_SUITE_BCH:-}" in
  python) run_python_bench ;;
  node) run_node_bench ;;
  all)
    run_python_bench
    run_node_bench
    ;;
  esac

  log_success "\n✨ Benchmarking finished."

  # 5. Standardized Next Actions
  if [ "${DRY_RUN:-0}" -eq 0 ] && [ "${_IS_TOP_LEVEL:-}" = "true" ]; then
    printf "\n%bNext Actions:%b\n" "${YELLOW}" "${NC}"
    printf "  - Run %bmake test%b for full functional verification.\n" "${GREEN}" "${NC}"
    printf "  - Run %bmake verify%b to ensure overall project health.\n" "${GREEN}" "${NC}"
  fi
}

main "$@"
