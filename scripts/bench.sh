#!/bin/sh
# scripts/bench.sh - Performance Benchmarker
# Standard entry point for benchmarking suites across the project.

set -e

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# 1. Execution Context Guard
guard_project_root

# ── Configuration ────────────────────────────────────────────────────────────

# Help Message
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

# Argument parsing
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  _SUITE="all"
  for _arg in "$@"; do
    case "$_arg" in
    python | node | all) _SUITE="$_arg" ;;
    esac
  done
  parse_common_args "$@"

  log_info "⚡ Starting Performance Benchmarker...\n"

  run_python_bench() {
    if find . -maxdepth 2 -name "*benchmark*" | grep -q .; then
      log_info "── Testing Python Benchmarks (pytest-benchmark) ──"
      if [ "$DRY_RUN" -eq 1 ]; then
        log_success "DRY-RUN: Would run pytest-benchmark"
      elif [ -x "$VENV/bin/pytest" ]; then
        "$VENV/bin/pytest" --benchmark-only
      else
        log_warn "pytest-benchmark not found. Skipping."
      fi
    fi
  }

  run_node_bench() {
    run_npm_script "bench"
  }

  case "$_SUITE" in
  python) run_python_bench ;;
  node) run_node_bench ;;
  all)
    run_python_bench
    run_node_bench
    ;;
  esac

  log_success "\n✨ Benchmarking finished."
}

main "$@"
