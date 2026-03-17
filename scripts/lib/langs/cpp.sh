#!/usr/bin/env sh
# C/C++ Logic Module

# Purpose: Installs C/C++ toolchain via mise or system package manager.
# Delegate: Managed by mise (.mise.toml)
install_runtime_cpp() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_debug "DRY_RUN: Would install C/C++ toolchain (gcc, clang, cmake, ninja)."
    return 0
  fi

  # Prefer mise if configured, otherwise rely on system-level guards
  if command -v mise >/dev/null 2>&1; then
    # shellcheck disable=SC2154
    run_mise install "llvm@${MISE_TOOL_VERSION_LLVM}"
    run_mise install cmake
    run_mise install ninja
    eval "$(mise activate bash --shims)"
  fi

  # System level check for compiler
  if ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
    log_warn "No C/C++ compiler (gcc/clang) detected. Please install build-essential or xcode-select."
    return 1
  fi
}

# Purpose: Sets up C/C++ environment for project.
setup_cpp() {
  local _T0_CPP_RT
  _T0_CPP_RT=$(date +%s)
  _log_setup "C/C++ Toolchain" "cpp"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Runtime" "C/C++" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect CMake, Makefile, or source files
  if ! has_lang_files "CMakeLists.txt Makefile" "*.cpp *.c *.cc *.h *.hpp"; then
    log_summary "Runtime" "C/C++" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_CPP_RT="✅ Installed"
  install_runtime_cpp || _STAT_CPP_RT="❌ Failed"

  local _DUR_CPP_RT
  _DUR_CPP_RT=$(($(date +%s) - _T0_CPP_RT))

  local _CPP_VER
  if command -v clang >/dev/null 2>&1; then
    _CPP_VER=$(get_version clang | head -n 1)
  else
    _CPP_VER=$(get_version gcc | head -n 1)
  fi

  log_summary "Runtime" "C/C++" "$_STAT_CPP_RT" "$_CPP_VER" "$_DUR_CPP_RT"
}

# Purpose: Checks if C/C++ toolchain is available.
# Examples:
#   check_runtime_cpp "Linter"
check_runtime_cpp() {
  local _TOOL_DESC_CPP="${1:-C/C++}"
  if ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
    log_warn "Required runtime 'gcc' or 'clang' for $_TOOL_DESC_CPP is missing. Skipping."
    return 1
  fi
  return 0
}
