#!/usr/bin/env sh
# Tool Registry - Centralized version management for dynamic registration

# Purpose: Registers a tool in .mise.toml if it's not already present.
# Params:
#   $1 - Tool name (internal)
#   $2 - Mise provider/name (e.g. asdf:ghc)
#   $3 - Version string
register_mise_tool() {
  local _NAME="$1"
  local _PROVIDER="$2"
  local _VERSION="$3"

  # Check if already in .mise.toml
  if grep -qE "^\"?${_PROVIDER}\"?[[:space:]]*=" "$(get_project_root)/.mise.toml" 2>/dev/null; then
    return 0
  fi

  log_info "Dynamically registering ${_NAME} SDK (${_PROVIDER}@${_VERSION})..."
  run_mise use "${_PROVIDER}@${_VERSION}"
}

# --- Registry Data ---
# Note: Core runtimes (Node, Python) are always in .mise.toml.
# Secondary runtimes (Go, Rust, Java, etc.) are dynamically registered
# only when their source files are detected or explicitly requested.

setup_registry_go() { register_mise_tool "Go" "go" "${VER_GO}"; }
setup_registry_rust() { register_mise_tool "Rust" "rust" "${VER_RUST}"; }
setup_registry_java() { register_mise_tool "Java" "java" "${VER_JAVA}"; }
setup_registry_dotnet() { register_mise_tool ".NET" "dotnet" "${VER_DOTNET}"; }
setup_registry_zig() { register_mise_tool "Zig" "zig" "${VER_ZIG}"; }
setup_registry_bun() { register_mise_tool "Bun" "bun" "${VER_BUN}"; }
setup_registry_deno() { register_mise_tool "Deno" "deno" "${VER_DENO}"; }

setup_registry_ada() { register_mise_tool "Ada" "asdf:ada" "14.2.0"; }
setup_registry_clojure() { register_mise_tool "Clojure" "asdf:clojure" "1.12.0.1479"; }
setup_registry_crystal() { register_mise_tool "Crystal" "asdf:crystal" "1.15.1"; }
setup_registry_dart() { register_mise_tool "Dart" "asdf:dart" "3.7.0"; }
setup_registry_dlang() { register_mise_tool "Dlang" "asdf:dlang" "2.109.1"; }
setup_registry_elixir() { register_mise_tool "Elixir" "elixir" "1.18.2-otp-27"; }
setup_registry_elm() { register_mise_tool "Elm" "elm" "0.19.1"; }
setup_registry_erlang() { register_mise_tool "Erlang" "erlang" "27.2.2"; }
setup_registry_fpc() { register_mise_tool "FPC" "asdf:fpc" "3.2.2"; }
setup_registry_gcc() { register_mise_tool "GCC" "asdf:gcc" "15.2"; }
setup_registry_ghc() { register_mise_tool "GHC" "asdf:ghc" "9.10.1"; }
setup_registry_ormolu() { register_mise_tool "Ormolu" "ormolu" "0.7.7.0"; }
setup_registry_gleam() { register_mise_tool "Gleam" "asdf:gleam" "1.8.1"; }
setup_registry_groovy() { register_mise_tool "Groovy" "asdf:groovy" "4.0.25"; }
setup_registry_haxe() { register_mise_tool "Haxe" "asdf:haxe" "4.3.6"; }
setup_registry_julia() { register_mise_tool "Julia" "asdf:julia" "1.11.3"; }
setup_registry_kotlin() { register_mise_tool "Kotlin" "asdf:kotlin" "2.1.10"; }
setup_registry_lean() { register_mise_tool "Lean" "asdf:lean" "4.26.0"; }
setup_registry_llvm() { register_mise_tool "LLVM" "asdf:llvm" "19.1.7"; }
setup_registry_lua() { register_mise_tool "Lua" "asdf:lua" "5.4.7"; }
setup_registry_luau() { register_mise_tool "Luau" "asdf:luau" "0.712"; }
setup_registry_mojo() { register_mise_tool "Mojo" "asdf:mojo" "0.26.1"; }
setup_registry_nim() { register_mise_tool "Nim" "asdf:nim" "2.2.0"; }
setup_registry_ocaml() { register_mise_tool "OCaml" "asdf:ocaml" "5.3.0"; }
setup_registry_odin() { register_mise_tool "Odin" "asdf:odin" "dev-2026-03"; }
setup_registry_perl() { register_mise_tool "Perl" "asdf:perl" "5.40.0"; }
setup_registry_php() { register_mise_tool "PHP" "asdf:php" "8.3.16"; }
setup_registry_r() { register_mise_tool "R" "asdf:R" "4.4.2"; }
setup_registry_racket() { register_mise_tool "Racket" "asdf:racket" "9.1"; }
setup_registry_raku() { register_mise_tool "Raku" "asdf:raku" "2026.02"; }
setup_registry_rescript() { register_mise_tool "ReScript" "asdf:rescript" "12.0.0"; }
setup_registry_ruby() { register_mise_tool "Ruby" "ruby" "3.4.2"; }
setup_registry_sbcl() { register_mise_tool "SBCL" "asdf:sbcl" "2.6.2"; }
setup_registry_scala() { register_mise_tool "Scala" "asdf:scala" "3.6.3"; }
setup_registry_scalafmt() { register_mise_tool "Scalafmt" "scalafmt" "3.8.3"; }
setup_registry_solc() { register_mise_tool "Solc" "asdf:solc" "0.8.28"; }
setup_registry_swift() { register_mise_tool "Swift" "asdf:swift" "6.0.3"; }
setup_registry_prolog() { register_mise_tool "Prolog" "asdf:swi-prolog" "10.1.5"; }
setup_registry_tcl() { register_mise_tool "Tcl" "asdf:tcl" "9.0.3"; }
setup_registry_vlang() { register_mise_tool "Vlang" "asdf:vlang" "0.5.1"; }
setup_registry_wasmtime() { register_mise_tool "Wasmtime" "asdf:wasmtime" "42.0.1"; }
setup_registry_grain() { register_mise_tool "Grain" "github:grain-lang/grain" "0.7.2"; }
setup_registry_moonbit() { register_mise_tool "Moonbit" "github:moonbitlang/moonbit-compiler" "0.8.0"; }
setup_registry_kcl() { register_mise_tool "KCL" "asdf:kcl" "0.11.1"; }
setup_registry_move() { register_mise_tool "Move" "asdf:move" "1.2.0"; }
setup_registry_pkl() { register_mise_tool "Pkl" "asdf:pkl" "0.31.0"; }
setup_registry_bazel() { register_mise_tool "Bazel" "asdf:bazel" "9.0.1"; }
setup_registry_spark() { register_mise_tool "Spark" "asdf:spark" "4.1.1"; }
setup_registry_ballerina() { register_mise_tool "Ballerina" "github:ballerina-platform/ballerina-distribution" "2201.11.0"; }

# -- Secondary Tooling / Infrastructure / Linting --
setup_registry_kube_linter() { register_mise_tool "Kube-Linter" "${VER_KUBE_LINTER_PROVIDER:-github:stackrox/kube-linter}" "${VER_KUBE_LINTER:-latest}"; }
setup_registry_spectral() { register_mise_tool "Spectral" "${VER_SPECTRAL_PROVIDER:-npm:@stoplight/spectral-cli}" "${VER_SPECTRAL:-latest}"; }
setup_registry_buf() { register_mise_tool "Buf" "${VER_BUF_PROVIDER:-github:bufbuild/buf}" "${VER_BUF:-latest}"; }
setup_registry_trivy() { register_mise_tool "Trivy" "${VER_TRIVY_PROVIDER:-github:aquasecurity/trivy}" "${VER_TRIVY:-latest}"; }
setup_registry_osv_scanner() { register_mise_tool "OSV-Scanner" "${VER_OSV_SCANNER_PROVIDER:-github:google/osv-scanner}" "${VER_OSV_SCANNER:-latest}"; }
setup_registry_cargo_audit() { register_mise_tool "Cargo-Audit" "${VER_CARGO_AUDIT_PROVIDER:-cargo:cargo-audit}" "${VER_CARGO_AUDIT:-latest}"; }
setup_registry_tflint() { register_mise_tool "TFLint" "${VER_TFLINT_PROVIDER:-github:terraform-linters/tflint}" "${VER_TFLINT:-latest}"; }
setup_registry_tofu() { register_mise_tool "OpenTofu" "${VER_TOFU_PROVIDER:-github:opentofu/opentofu}" "${VER_TOFU:-latest}"; }
setup_registry_just() { register_mise_tool "Just" "${VER_JUST_PROVIDER:-github:casey/just}" "${VER_JUST:-latest}"; }
setup_registry_task() { register_mise_tool "Task" "${VER_TASK_PROVIDER:-github:go-task/task}" "${VER_TASK:-latest}"; }
