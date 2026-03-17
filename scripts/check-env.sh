#!/usr/bin/env sh
# scripts/check-env.sh - Environment Health Auditor
#
# Purpose:
#   Validates the developer workstation against project-required runtimes and tools.
#   Identifies missing dependencies or version mismatches before development starts.
#
# Usage:
#   sh scripts/check-env.sh [OPTIONS]
#
# Standards:
#   - POSIX-compliant sh logic.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 08 (Dev Env).
#
# Features:
#   - POSIX compliant, encapsulated main() pattern.
#   - Language-aware runtime detection (Node, Go, Python, etc.).
#   - High-performance, non-destructive validation scans.

# set -e removed to allow full diagnostic reporting

# ── Common Library ───────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/common.sh"

# ── Global State (Scoped to script) ──────────────────────────────────────────
HEALTHY_ST=0
CORE_HEALTHY_ST=0

# ── Functions ────────────────────────────────────────────────────────────────

# Purpose: Displays usage information for the environment health auditor.
# Examples:
#   show_help
# shellcheck disable=SC2317,SC2329
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Checks the health of the development environment.

Options:
  -q, --quiet      Suppress informational output.
  -v, --verbose    Enable verbose/debug output.
  -h, --help       Show this help message.

EOF
}

# Purpose: Internal helper for version checking of a specific tool.
# Params:
#   $1 - Human-readable name
#   $2 - Command to verify
#   $3 - Minimum required version
#   $4 - Version check command
#   $5 - Critical flag (1 for core, 0 for optional)
#   $6 - CI-only flag (1 to skip locally with info, 0 to always check)
# Examples:
#   check_tool_version "Git" "git" "2.30.0" "git --version" 1
check_tool_version() {
  local _LV_NAME="$1"
  local _LV_CMD="$2"
  local _LV_MIN_VER="$3"
  local _LV_VER_CMD="$4"
  local _LV_CRITICAL="${5:-0}"
  local _LV_CI_ONLY="${6:-0}"

  log_debug "Checking $_LV_NAME (min: $_LV_MIN_VER)..."

  if ! command -v "$_LV_CMD" >/dev/null 2>&1; then
    if [ "$_LV_CI_ONLY" -eq 1 ] && ! is_ci_env; then
      log_info "⏭️  $_LV_NAME: CI-only (skipped locally)"
      return 0
    fi
    log_warn "❌ $_LV_NAME: Not found."
    HEALTHY_ST=1
    [ "${_LV_CRITICAL:-0}" -eq 1 ] && CORE_HEALTHY_ST=1
    return 1
  fi

  local _LV_CURRENT_VER
  _LV_CURRENT_VER=$(get_version "$_LV_CMD" | tr -d '\r')
  [ "$_LV_CURRENT_VER" = "-" ] && _LV_CURRENT_VER="0.0"

  # If requirement is empty or -, allow anything
  if [ -z "$_LV_MIN_VER" ] || [ "$_LV_MIN_VER" = "-" ]; then
    log_success "✅ $_LV_NAME: v$_LV_CURRENT_VER (detected)"
    return 0
  fi

  local _LV_LOWER_VER
  _LV_LOWER_VER=$(printf "%s\n%s" "$_LV_MIN_VER" "$_LV_CURRENT_VER" | sort -n -t. -k1,1 -k2,2 -k3,3 | head -n1)

  if [ "$_LV_LOWER_VER" = "$_LV_MIN_VER" ] || [ "$_LV_CURRENT_VER" = "$_LV_MIN_VER" ]; then
    log_success "✅ $_LV_NAME: v$_LV_CURRENT_VER (matches/exceeds v$_LV_MIN_VER)"
  else
    log_warn "⚠️  $_LV_NAME: v$_LV_CURRENT_VER (below recommended v$_LV_MIN_VER)"
    HEALTHY_ST=1
    [ "${_LV_CRITICAL:-0}" -eq 1 ] && CORE_HEALTHY_ST=1
  fi
}

# Purpose: Main entry point for the environment health auditing engine.
# Params:
#   $@ - Command line arguments
# Examples:
#   main --verbose
main() {
  # 1. Execution Context Guard
  guard_project_root

  # 2. Argument Parsing
  parse_common_args "$@"

  log_info "🔍 Checking Development Environment Health...\n"

  # 3. Group: Core Infrastructure
  log_info "── Core Infrastructure ──"
  check_tool_version "Git" "git" "2.30.0" "git --version" 1

  if command -v make >/dev/null 2>&1; then
    log_success "✅ Make: Installed"
  else
    log_error "❌ Make: Not found."
    HEALTHY_ST=1
    CORE_HEALTHY_ST=1
  fi

  if command -v docker >/dev/null 2>&1; then
    log_success "✅ Docker: Installed"
  else
    log_warn "⚠️  Docker: Not found (optional for some tasks)"
  fi
  printf "\n"

  # 4. Group: Language Runtimes (Dynamic Modular Verification)
  log_info "── Language Runtimes ──"

  # Node.js
  if [ -f "$PACKAGE_JSON" ]; then
    check_tool_version "Node.js" "node" "$(get_mise_tool_version node)" "node -v" 1
    check_tool_version "pnpm" "pnpm" "$(get_mise_tool_version pnpm)" "pnpm -v"
  else
    log_info "⏭️  Node.js/pnpm: Skipped (no package.json)"
  fi

  # Front-end tools (Modular)
  check_runtime "node" "Node.js"
  check_runtime "deno" "Deno"
  check_runtime "bun" "Bun"
  check_runtime "vue" "Vue"
  check_runtime "svelte" "Svelte"
  check_runtime "astro" "Astro"
  check_runtime "liquid" "Liquid"
  check_runtime "solid" "SolidJS"
  check_runtime "qwik" "Qwik"
  check_runtime "sass" "Sass"
  check_runtime "less" "Less"
  check_runtime "pug" "Pug"
  check_runtime "handlebars" "Handlebars"
  check_runtime "ejs" "EJS"
  check_runtime "htmx" "HTMX"
  check_runtime "alpine" "Alpine.js"
  check_runtime "stylus" "Stylus"
  check_runtime "postcss" "PostCSS"
  check_runtime "lit" "Lit"
  check_runtime "capacitor" "Capacitor"
  check_runtime "awk" "AWK"
  check_runtime "sed" "Sed"

  # Python
  if has_lang_files "requirements.txt requirements-dev.txt pyproject.toml" "*.py"; then
    check_tool_version "Python" "$PYTHON" "$(get_mise_tool_version python)" "$PYTHON --version" 1
    check_runtime "python" "Python (Modular)"
  else
    log_info "⏭️  Python: Skipped (no python files)"
  fi

  # Go
  if has_lang_files "go.mod" "*.go"; then
    check_tool_version "Go" "go" "1.21.0" "go version" 0
    check_runtime "go" "Go (Modular)"
  else
    log_info "⏭️  Go: Skipped (no go files)"
  fi

  # Ruby
  if has_lang_files "Gemfile .ruby-version package.json" "*.rb"; then
    check_tool_version "Ruby" "ruby" "3.0.0" "ruby -v" 0
    check_runtime "ruby" "Ruby (Modular)"
  else
    log_info "⏭️  Ruby: Skipped (no ruby files)"
  fi

  # Java
  if has_lang_files "pom.xml build.gradle" "*.java"; then
    check_tool_version "Java" "java" "17" "java -version" 0
    check_runtime "java" "Java (Modular)"
  else
    log_info "⏭️  Java: Skipped (no java files)"
  fi

  # PHP
  if has_lang_files "composer.json" "*.php"; then
    check_tool_version "PHP" "php" "8.0.0" "php -v" 0
    check_runtime "php" "PHP (Modular)"
  else
    log_info "⏭️  PHP: Skipped (no php files)"
  fi

  # .NET
  if has_lang_files "global.json" "*.csproj *.sln *.cs"; then
    check_tool_version ".NET" "dotnet" "6.0.0" "dotnet --version" 0
    check_runtime "dotnet" "Dotnet (Modular)"
  else
    log_info "⏭️  .NET: Skipped (no dotnet files)"
  fi

  # Rust
  if has_lang_files "Cargo.toml" "*.rs"; then
    check_tool_version "Rust" "cargo" "1.70.0" "cargo --version" 0
    check_runtime "rust" "Rust (Modular)"
  else
    log_info "⏭️  Rust: Skipped (no rust files)"
  fi

  # C/C++
  if has_lang_files "*.c *.cpp *.h *.hpp"; then
    check_runtime "cpp" "C/C++"
  else
    log_info "⏭️  C/C++: Skipped (no C/C++ files)"
  fi

  # Assembly
  if has_lang_files "*.s *.asm"; then
    check_runtime "assembly" "Assembly (Modular)"
  else
    log_info "⏭️  Assembly: Skipped (no Assembly files)"
  fi

  # Terraform
  if has_lang_files "" "*.tf *.tfvars *.hcl"; then
    check_runtime "terraform" "Terraform (Modular)"
  else
    log_info "⏭️  Terraform: Skipped (no Terraform files)"
  fi

  # Solidity
  if has_lang_files "" "*.sol"; then
    check_runtime "solidity" "Solidity (Modular)"
  else
    log_info "⏭️  Solidity: Skipped (no Solidity files)"
  fi

  # Nix
  if has_lang_files "flake.nix shell.nix default.nix" "*.nix"; then
    check_runtime "nix" "Nix (Modular)"
  else
    log_info "⏭️  Nix: Skipped (no Nix files)"
  fi

  # Odin
  if has_lang_files "" "*.odin"; then
    check_runtime "odin" "Odin (Modular)"
  else
    log_info "⏭️  Odin: Skipped (no Odin files)"
  fi

  # Nim
  if has_lang_files "nim.cfg nimble.ini" "*.nim *.nims *.nimble"; then
    check_runtime "nim" "Nim (Modular)"
  else
    log_info "⏭️  Nim: Skipped (no Nim files)"
  fi

  # Clojure
  if has_lang_files "project.clj deps.edn bb.edn" "*.clj *.cljs *.cljc *.edn"; then
    check_runtime "clojure" "Clojure (Modular)"
  else
    log_info "⏭️  Clojure: Skipped (no Clojure files)"
  fi

  # Gleam
  if has_lang_files "gleam.toml" "*.gleam"; then
    check_runtime "gleam" "Gleam (Modular)"
  else
    log_info "⏭️  Gleam: Skipped (no Gleam files)"
  fi

  # Mojo
  if has_lang_files "" "*.mojo *.fire"; then
    check_runtime "mojo" "Mojo (Modular)"
  else
    log_info "⏭️  Mojo: Skipped (no Mojo files)"
  fi

  # Objective-C
  if has_lang_files "" "*.m *.mm"; then
    check_runtime "objc" "Objective-C (Modular)"
  else
    log_info "⏭️  Objective-C: Skipped (no Objective-C files)"
  fi

  # OCaml
  if has_lang_files "dune-project dune opam" "*.ml *.mli *.mll *.mly"; then
    check_runtime "ocaml" "OCaml (Modular)"
  else
    log_info "⏭️  OCaml: Skipped (no OCaml files)"
  fi

  # F#
  if has_lang_files "" "*.fs *.fsi *.fsx *.fsproj"; then
    check_runtime "fsharp" "F# (Modular)"
  else
    log_info "⏭️  F#: Skipped (no F# files)"
  fi

  # Erlang
  if has_lang_files "rebar.config erlang.mk" "*.erl *.hrl"; then
    check_runtime "erlang" "Erlang (Modular)"
  else
    log_info "⏭️  Erlang: Skipped (no Erlang files)"
  fi

  # Vlang
  if has_lang_files "v.mod" "*.v *.vsh"; then
    check_runtime "vlang" "Vlang (Modular)"
  else
    log_info "⏭️  Vlang: Skipped (no Vlang files)"
  fi

  # Crystal
  if has_lang_files "shard.yml" "*.cr"; then
    check_runtime "crystal" "Crystal (Modular)"
  else
    log_info "⏭️  Crystal: Skipped (no Crystal files)"
  fi

  # Dlang
  if has_lang_files "dub.json dub.sdl" "*.d"; then
    check_runtime "dlang" "Dlang (Modular)"
  else
    log_info "⏭️  Dlang: Skipped (no Dlang files)"
  fi

  # Haxe
  if has_lang_files "project.xml build.hxml" "*.hx"; then
    check_runtime "haxe" "Haxe (Modular)"
  else
    log_info "⏭️  Haxe: Skipped (no Haxe files)"
  fi

  # AssemblyScript
  if has_lang_files "asconfig.json" "*.as"; then
    check_runtime "assemblyscript" "AssemblyScript (Modular)"
  else
    log_info "⏭️  AssemblyScript: Skipped (no AssemblyScript files)"
  fi

  # Ballerina
  if has_lang_files "Ballerina.toml" "*.bal"; then
    check_runtime "ballerina" "Ballerina (Modular)"
  else
    log_info "⏭️  Ballerina: Skipped (no Ballerina files)"
  fi

  # KCL
  if has_lang_files "kcl.mod" "*.k"; then
    check_runtime "kcl" "KCL (Modular)"
  else
    log_info "⏭️  KCL: Skipped (no KCL files)"
  fi

  # Pkl
  if has_lang_files "PklProject" "*.pkl"; then
    check_runtime "pkl" "Pkl (Modular)"
  else
    log_info "⏭️  Pkl: Skipped (no Pkl files)"
  fi

  # Move
  if has_lang_files "Move.toml" "*.move"; then
    check_runtime "move" "Move (Modular)"
  else
    log_info "⏭️  Move: Skipped (no Move files)"
  fi

  # Elm
  if has_lang_files "elm.json" "*.elm"; then
    check_runtime "elm" "Elm (Modular)"
  else
    log_info "⏭️  Elm: Skipped (no Elm files)"
  fi

  # ReScript
  if has_lang_files "rescript.json bsconfig.json" "*.res *.resi"; then
    check_runtime "rescript" "ReScript (Modular)"
  else
    log_info "⏭️  ReScript: Skipped (no ReScript files)"
  fi

  # Ada
  if has_lang_files "*.adb *.ads *.gpr"; then
    check_runtime "ada" "Ada (Modular)"
  else
    log_info "⏭️  Ada: Skipped (no Ada files)"
  fi

  # Luau
  if has_lang_files "*.luau"; then
    check_runtime "luau" "Luau (Modular)"
  else
    log_info "⏭️  Luau: Skipped (no Luau files)"
  fi

  # Raku
  if has_lang_files "META6.json" "*.raku *.rakumod *.p6 *.pm6"; then
    check_runtime "raku" "Raku (Modular)"
  else
    log_info "⏭️  Raku: Skipped (no Raku files)"
  fi

  # Vala
  if has_lang_files "*.vala *.vapi"; then
    check_runtime "vala" "Vala (Modular)"
  else
    log_info "⏭️  Vala: Skipped (no Vala files)"
  fi

  # Free Pascal
  if has_lang_files "*.pas *.pp *.inc *.lpr"; then
    check_runtime "fpc" "Free Pascal (Modular)"
  else
    log_info "⏭️  Free Pascal: Skipped (no Pascal files)"
  fi

  # Lean 4
  if has_lang_files "lean-toolchain lakefile.lean" "*.lean"; then
    check_runtime "lean" "Lean 4 (Modular)"
  else
    log_info "⏭️  Lean 4: Skipped (no Lean files)"
  fi

  # Common Lisp
  if has_lang_files "*.lisp *.cl *.asd"; then
    check_runtime "lisp" "Common Lisp (Modular)"
  else
    log_info "⏭️  Common Lisp: Skipped (no Lisp files)"
  fi

  # Racket
  if has_lang_files "*.rkt *.rktl"; then
    check_runtime "racket" "Racket (Modular)"
  else
    log_info "⏭️  Racket: Skipped (no Racket files)"
  fi

  # Prolog
  if has_lang_files "*.pl *.pro *.prolog"; then
    check_runtime "prolog" "Prolog (Modular)"
  else
    log_info "⏭️  Prolog: Skipped (no Prolog files)"
  fi

  # PowerShell
  if has_lang_files "*.ps1 *.psm1 *.psd1"; then
    check_runtime "pwsh" "PowerShell (Modular)"
  else
    log_info "⏭️  PowerShell: Skipped (no PowerShell files)"
  fi

  # Fortran
  if has_lang_files "*.f *.for *.f90 *.f95"; then
    check_runtime "fortran" "Fortran (Modular)"
  else
    log_info "⏭️  Fortran: Skipped (no Fortran files)"
  fi

  # WebAssembly Text
  if has_lang_files "*.wat *.wasm"; then
    check_runtime "wat" "WebAssembly (Modular)"
  else
    log_info "⏭️  WebAssembly: Skipped (no Wasm files)"
  fi

  # MoonBit
  if has_lang_files "moon.pkg.json" "*.mbt"; then
    check_runtime "moonbit" "MoonBit (Modular)"
  else
    log_info "⏭️  MoonBit: Skipped (no MoonBit files)"
  fi

  # Grain
  if has_lang_files "*.gr"; then
    check_runtime "grain" "Grain (Modular)"
  else
    log_info "⏭️  Grain: Skipped (no Grain files)"
  fi

  # Jsonnet
  if has_lang_files "*.jsonnet *.libsonnet"; then
    check_runtime "jsonnet" "Jsonnet (Modular)"
  else
    log_info "⏭️  Jsonnet: Skipped (no Jsonnet files)"
  fi

  # Starlark
  if has_lang_files "*.star *.bzl BUILD WORKSPACE MODULE.bazel"; then
    check_runtime "starlark" "Starlark (Modular)"
  else
    log_info "⏭️  Starlark: Skipped (no Starlark files)"
  fi

  # Tcl
  if has_lang_files "*.tcl *.tk"; then
    check_runtime "tcl" "Tcl (Modular)"
  else
    log_info "⏭️  Tcl: Skipped (no Tcl files)"
  fi

  # DuckDB
  if has_lang_files "*.sql *.duckdb"; then
    check_runtime "duckdb" "DuckDB (Modular)"
  else
    log_info "⏭️  DuckDB: Skipped (no SQL/DuckDB files)"
  fi

  # VCPKG
  if has_lang_files "vcpkg.json vcpkg-configuration.json"; then
    check_runtime "vcpkg" "VCPKG (Modular)"
  else
    log_info "⏭️  VCPKG: Skipped (no VCPKG files)"
  fi

  # Gherkin
  if has_lang_files "*.feature"; then
    check_runtime "gherkin" "Gherkin (Modular)"
  else
    log_info "⏭️  Gherkin: Skipped (no Gherkin files)"
  fi

  # Terragrunt
  if has_lang_files "terragrunt.hcl"; then
    check_runtime "terragrunt" "Terragrunt (Modular)"
  else
    log_info "⏭️  Terragrunt: Skipped (no Terragrunt files)"
  fi

  # Apache Spark
  if has_lang_files "spark-defaults.conf *.pyspark"; then
    check_runtime "spark" "Apache Spark (Modular)"
  else
    log_info "⏭️  Apache Spark: Skipped (no Spark files)"
  fi

  # Helm
  if has_lang_files "Chart.yaml"; then
    check_runtime "helm" "Helm (Modular)"
  else
    log_info "⏭️  Helm: Skipped (no Chart.yaml)"
  fi

  # Kustomize
  if has_lang_files "kustomization.yaml kustomization.yml"; then
    check_runtime "kustomize" "Kustomize (Modular)"
  else
    log_info "⏭️  Kustomize: Skipped (no kustomization.yaml)"
  fi

  # GraphQL
  if has_lang_files "*.graphql *.gql"; then
    check_runtime "graphql" "GraphQL (Modular)"
  else
    log_info "⏭️  GraphQL: Skipped (no GraphQL files)"
  fi

  # Typst
  if has_lang_files "*.typ"; then
    check_runtime "typst" "Typst (Modular)"
  else
    log_info "⏭️  Typst: Skipped (no Typst files)"
  fi

  # Verilog
  if has_lang_files "*.v"; then
    check_runtime "verilog" "Verilog (Modular)"
  else
    log_info "⏭️  Verilog: Skipped (no .v files)"
  fi

  # SystemVerilog
  if has_lang_files "*.sv *.svh"; then
    check_runtime "systemverilog" "SystemVerilog (Modular)"
  else
    log_info "⏭️  SystemVerilog: Skipped (no .sv files)"
  fi

  # VHDL
  if has_lang_files "*.vhd *.vhdl"; then
    check_runtime "vhdl" "VHDL (Modular)"
  else
    log_info "⏭️  VHDL: Skipped (no VHDL files)"
  fi

  # Octave / MATLAB
  if has_lang_files "*.m"; then
    check_runtime "octave" "Octave (Modular)"
    check_runtime "matlab" "MATLAB (Modular)"
  else
    log_info "⏭️  Octave/MATLAB: Skipped (no .m files)"
  fi

  # OpenAPI
  if has_lang_files "openapi.yaml openapi.json swagger.yaml swagger.json"; then
    check_runtime "openapi" "OpenAPI (Modular)"
  else
    log_info "⏭️  OpenAPI: Skipped (no OpenAPI files)"
  fi

  # AsyncAPI
  if has_lang_files "asyncapi.yaml asyncapi.yml asyncapi.json"; then
    check_runtime "asyncapi" "AsyncAPI (Modular)"
  else
    log_info "⏭️  AsyncAPI: Skipped (no AsyncAPI files)"
  fi

  # PromQL
  if has_lang_files "*.promql"; then
    check_runtime "promql" "PromQL (Modular)"
  else
    log_info "⏭️  PromQL: Skipped (no PromQL files)"
  fi

  # LaTeX
  if has_lang_files "*.tex *.bib"; then
    check_runtime "latex" "LaTeX (Modular)"
  else
    log_info "⏭️  LaTeX: Skipped (no LaTeX files)"
  fi

  # Protobuf
  if has_lang_files "*.proto"; then
    check_runtime "proto" "Protobuf (Modular)"
  else
    log_info "⏭️  Protobuf: Skipped (no .proto files)"
  fi

  # Avro
  if has_lang_files "*.avsc"; then
    check_runtime "avro" "Avro (Modular)"
  else
    log_info "⏭️  Avro: Skipped (no .avsc files)"
  fi

  # Thrift
  if has_lang_files "*.thrift"; then
    check_runtime "thrift" "Thrift (Modular)"
  else
    log_info "⏭️  Thrift: Skipped (no .thrift files)"
  fi

  # Prisma
  if has_lang_files "schema.prisma" "*.prisma"; then
    check_runtime "prisma" "Prisma (Modular)"
  else
    log_info "⏭️  Prisma: Skipped (no .prisma files)"
  fi

  # FlatBuffers
  if has_lang_files "*.fbs"; then
    check_runtime "flatbuffers" "FlatBuffers (Modular)"
  else
    log_info "⏭️  FlatBuffers: Skipped (no .fbs files)"
  fi

  # EdgeDB
  if has_lang_files "edgedb.toml" "*.esdl"; then
    check_runtime "edgedb" "EdgeDB (Modular)"
  else
    log_info "⏭️  EdgeDB: Skipped (no .esdl files)"
  fi

  # SurrealDB
  if has_lang_files "*.surql"; then
    check_runtime "surrealdb" "SurrealDB (Modular)"
    check_runtime "plsql" "PL/SQL (Modular)"
    check_runtime "tsql" "T-SQL (Modular)"
    check_runtime "cobol" "COBOL (Modular)"
    check_runtime "prql" "PRQL (Modular)"
  else
    log_info "⏭️  SurrealDB: Skipped (no .surql files)"
  fi

  # CUDA
  if has_lang_files "*.cu *.cuh"; then
    check_runtime "cuda" "CUDA (Modular)"
  else
    log_info "⏭️  CUDA: Skipped (no CUDA files)"
  fi

  # Bicep
  if has_lang_files "*.bicep"; then
    check_runtime "bicep" "Bicep (Modular)"
  else
    log_info "⏭️  Bicep: Skipped (no Bicep files)"
  fi

  # CloudFormation
  if has_lang_files "*.template *.cfn.yaml *.cfn.json"; then
    check_runtime "cloudformation" "CloudFormation (Modular)"
  else
    log_info "⏭️  CloudFormation: Skipped (no CloudFormation files)"
  fi

  # ArkTS
  if has_lang_files "*.ets"; then
    check_runtime "arkts" "ArkTS (Modular)"
  else
    log_info "⏭️  ArkTS: Skipped (no ArkTS files)"
  fi

  # Shader
  if has_lang_files "*.hlsl *.glsl *.vert *.frag *.comp"; then
    check_runtime "shader" "Shader (Modular)"
  else
    log_info "⏭️  Shader: Skipped (no Shader files)"
  fi

  # GDScript
  if has_lang_files "*.gd"; then
    check_runtime "gdscript" "GDScript (Modular)"
  else
    log_info "⏭️  GDScript: Skipped (no GDScript files)"
  fi

  # QML
  if has_lang_files "*.qml"; then
    check_runtime "qml" "QML (Modular)"
  else
    log_info "⏭️  QML: Skipped (no QML files)"
  fi

  # Apex
  if has_lang_files "*.cls *.trigger"; then
    check_runtime "apex" "Apex (Modular)"
  else
    log_info "⏭️  Apex: Skipped (no Apex files)"
  fi

  # AppleScript
  if has_lang_files "*.applescript *.scpt"; then
    check_runtime "applescript" "AppleScript (Modular)"
  else
    log_info "⏭️  AppleScript: Skipped (no AppleScript files)"
  fi

  # VBA
  if has_lang_files "*.vba *.bas *.cls"; then
    check_runtime "vba" "VBA (Modular)"
  else
    log_info "⏭️  VBA: Skipped (no VBA files)"
  fi

  # Tauri
  if has_lang_files "tauri.conf.json src-tauri/tauri.conf.json"; then
    check_runtime "tauri" "Tauri (Modular)"
  else
    log_info "⏭️  Tauri: Skipped (no tauri.conf.json)"
  fi

  # Electron
  if [ -f "package.json" ] && grep -q '"electron"' package.json; then
    check_runtime "electron" "Electron (Modular)"
  else
    log_info "⏭️  Electron: Skipped (no electron in package.json)"
  fi
  printf "\n"

  # 5. Group: Mobile Support
  if has_lang_files "Package.swift pubspec.yaml build.gradle.kts" "*.swift *.kt *.dart"; then
    log_info "── Mobile Support ──"
    if has_lang_files "Package.swift" "*.swift"; then check_tool_version "Swift" "swift" "5.0" "swift --version" 0; fi
    if has_lang_files "build.gradle.kts" "*.kt *.kts"; then check_tool_version "Kotlin" "kotlin" "1.9.0" "kotlin -version" 0; fi
    if [ -f "pubspec.yaml" ] || has_lang_files "" "*.dart"; then
      if command -v flutter >/dev/null 2>&1; then
        check_tool_version "Flutter" "flutter" "3.0.0" "flutter --version" 0
      else check_tool_version "Dart" "dart" "3.0.0" "dart --version" 0; fi
    fi
    printf "\n"
  fi

  log_info "── Toolchain Manager ──"
  if command -v mise >/dev/null 2>&1; then
    log_success "✅ mise: Active ($(get_version mise))"
  else
    log_warn "❌ mise: Not found. (Mandatory for toolchain management)"
    HEALTHY_ST=1
  fi
  printf "\n"

  # 7. Group: Security & Quality Tools
  log_info "── Security & Quality Tools ──"
  check_tool_version "Gitleaks" "gitleaks" "$(get_mise_tool_version gitleaks)" "gitleaks version" 0 0
  check_tool_version "OSV-scanner" "osv-scanner" "$(get_mise_tool_version osv-scanner)" "osv-scanner --version" 0 1
  check_tool_version "Trivy" "trivy" "$(get_mise_tool_version trivy)" "trivy --version" 0 1
  check_tool_version "Zizmor" "zizmor" "$(get_mise_tool_version zizmor)" "zizmor --version" 0 1

  log_info "── Lint & Quality Tools ──"
  check_tool_version "Shfmt" "shfmt" "$(get_mise_tool_version shfmt-py)" "shfmt --version" 0 0
  check_tool_version "Shellcheck" "shellcheck" "$(get_mise_tool_version shellcheck-py)" "shellcheck --version" 0 0
  check_tool_version "Actionlint" "actionlint" "$(get_mise_tool_version actionlint-py)" "actionlint --version" 0 0
  check_tool_version "EditorConfig" "editorconfig-checker" "$(get_mise_tool_version editorconfig-checker)" "editorconfig-checker --version" 0 0

  if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ]; then
    check_tool_version "Hadolint" "hadolint" "$(get_mise_tool_version hadolint)" "hadolint --version" 0 0
  fi
  if has_lang_files "go.mod" "*.go"; then
    check_tool_version "golangci-lint" "golangci-lint" "$(get_mise_tool_version golangci-lint)" "golangci-lint --version" 0 0
    check_tool_version "Govulncheck" "govulncheck" "latest" "govulncheck ./..." 0 1
  fi
  if has_lang_files "Makefile" "*.make"; then
    check_tool_version "Checkmake" "checkmake" "$(get_mise_tool_version checkmake)" "checkmake --version" 0 0
  fi
  if has_lang_files "Cargo.toml" "*.rs"; then
    check_tool_version "Cargo-audit" "cargo-audit" "latest" "cargo-audit --version" 0 1
  fi
  if has_lang_files "requirements.txt pyproject.toml" "*.py"; then
    check_tool_version "Pip-audit" "pip-audit" "$(get_mise_tool_version pip-audit)" "pip-audit --version" 0 1
  fi
  printf "\n"

  # 7. Project File Integrity
  log_info "── Project Integrity ──"
  local _f_chk
  for _f_chk in "Makefile" "README.md" ".agent/rules/01-general.md"; do
    if [ -f "$_f_chk" ]; then
      log_debug "Found $_f_chk"
    else
      log_error "❌ Missing critical file: $_f_chk"
      HEALTHY_ST=1
      CORE_HEALTHY_ST=1
    fi
  done
  [ "${CORE_HEALTHY_ST:-0}" -eq 0 ] && log_success "✅ Basic project structure is intact."

  # 8. Script Permissions Audit
  log_info "── Script Permissions ──"
  local _s_chk _p_err=0
  # Use a temporary file to avoid subshell variable loss with find | while read
  find scripts -name "*.sh" -type f >/tmp/scripts_to_check.txt
  while read -r _s_chk; do
    if [ -f "$_s_chk" ]; then
      # Check if it has a shebang
      if head -n 1 "$_s_chk" | grep -q "^#!"; then
        if [ ! -x "$_s_chk" ]; then
          log_error "❌ Script lacks executable bit: $_s_chk"
          _p_err=1
          HEALTHY_ST=1
        fi
      fi
    fi
  done </tmp/scripts_to_check.txt
  rm -f /tmp/scripts_to_check.txt

  if [ "$_p_err" -eq 0 ]; then
    log_success "✅ All automation scripts have correct executable permissions."
  fi

  # Final combined health check
  if [ "${HEALTHY_ST:-0}" -eq 0 ]; then
    log_success "\n✨ Environment is HEALTHY! Ready for development."
    exit 0
  elif [ "${CORE_HEALTHY_ST:-0}" -eq 0 ]; then
    log_warn "\n🛠️  Environment is FUNCTIONAL but has warnings (missing recommended/optional tools)."
    log_warn "💡 Run 'make setup' to address the warnings above."
    exit 0
  else
    log_error "\n❌ Environment is BROKEN. Critical tools or files are missing."
    log_error "Please fix the issues above to proceed."
    exit 1
  fi
}

main "$@"
