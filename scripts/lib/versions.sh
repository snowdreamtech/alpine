#!/usr/bin/env sh
# scripts/lib/versions.sh — Tier 2 Tool Version Registry
#
# Purpose:
#   Single Source of Truth for all on-demand (Tier 2) tool versions.
#   These tools are NOT listed in .mise.toml (to avoid global mise install
#   downloading everything). Versions are pinned here and referenced by
#   each scripts/lib/langs/*.sh module.
#
#   Tier 1 tools (always installed) have their versions in .mise.toml.
#   Tier 2 tools (on-demand) have their versions here.
#
# shellcheck disable=SC2034
# (Variables are used by sourcing scripts: lang modules and setup.sh)

# ── 🏗️ Language Runtimes ──────────────────────────────────────────────────────
VER_GO="1.23.6"
VER_KOTLIN="2.1.20"
VER_RUST="1.85.0"
VER_BUN="1.2.4"
VER_DENO="2.2.2"
VER_ZIG="0.14.0"
VER_JAVA="21.0.2"
VER_DOTNET="9.0.201"
VER_RUBY="3.2.10"
VER_YARN="1.22.22"

# ── 🧪 Exotic / Domain-Specific Runtimes ─────────────────────────────────────
VER_GRAIN="0.7.2"
VER_GRAIN_PROVIDER="github:grain-lang/grain"
VER_GRAIN_REF="grain-v0.7.2"

VER_MOONBIT="0.7.2"
VER_MOONBIT_PROVIDER="github:moonbitlang/moonbit-compiler"
VER_MOONBIT_REF="v0.7.2+c12686398"

VER_KCL="v0.11.2"
VER_KCL_PROVIDER="github:kcl-lang/kcl"

VER_PKL="0.31.0"
VER_PKL_PROVIDER="github:apple/pkl"

VER_BAZEL="9.0.1"
VER_BAZEL_PROVIDER="github:bazelbuild/bazel"

VER_BALLERINA="2201.11.0"
VER_BALLERINA_PROVIDER="github:ballerina-platform/ballerina-distribution"

VER_STYLUA="2.0.2"
VER_STYLUA_PROVIDER="github:JohnnyMorganz/StyLua"

VER_JUST="1.39.0"
VER_JUST_PROVIDER="github:casey/just"

VER_TASK="3.41.0"
VER_TASK_PROVIDER="github:go-task/task"

VER_TYPST="0.13.0"
VER_DUCKDB="1.5.0"
VER_LYCHEE="lychee-v0.23.0"
VER_LYCHEE_PROVIDER="github:lycheeverse/lychee"

# ── 🎨 Language Tooling (Linters/Formatters) ─────────────────────────────────
VER_KTLINT="1.12.0"
VER_KTLINT_PROVIDER="npm:@naturalcycles/ktlint"

VER_JAVA_FORMAT="v1.35.0"
VER_JAVA_FORMAT_PROVIDER="github:google/google-java-format"

VER_SWIFTLINT="0.63.2"
VER_SWIFTLINT_PROVIDER="github:realm/SwiftLint"

VER_STYLELINT="16.26.1"
VER_STYLELINT_PROVIDER="npm:stylelint"

VER_STYLELINT_CONFIG="37.0.0"
VER_STYLELINT_CONFIG_PROVIDER="npm:stylelint-config-standard"

VER_ASSEMBLYSCRIPT="0.27.31"
VER_ASSEMBLYSCRIPT_PROVIDER="npm:assemblyscript"

VER_OPA="1.2.0"
VER_OPA_PROVIDER="github:open-policy-agent/opa"

VER_BUF="1.50.0"
VER_BUF_PROVIDER="github:bufbuild/buf"

VER_CUE="0.12.0"
VER_CUE_PROVIDER="github:cue-lang/cue"

VER_JSONNET="0.20.0"
VER_JSONNET_PROVIDER="github:google/go-jsonnet"

VER_GOLANGCI_LINT="1.64.5"

VER_VITEPRESS="1.6.4"
VER_VITEPRESS_PROVIDER="npm:vitepress"

# ── 🛡️ Security Scanning (CI-only by default) ─────────────────────────────────
VER_TRIVY="0.69.3"
VER_TRIVY_PROVIDER="github:aquasecurity/trivy"

VER_OSV_SCANNER="2.3.3"
VER_OSV_SCANNER_PROVIDER="github:google/osv-scanner"

VER_GOVULNCHECK="v1.1.4"
VER_GOVULNCHECK_PROVIDER="go:golang.org/x/vuln/cmd/govulncheck"

VER_PIP_AUDIT="2.8.0"
VER_PIP_AUDIT_PROVIDER="pipx:pip-audit"

VER_CARGO_AUDIT="0.20.1"
VER_CARGO_AUDIT_PROVIDER="cargo:cargo-audit"

VER_ZIZMOR="1.3.1"
VER_ZIZMOR_PROVIDER="pipx:zizmor"

# ── ☁️ DevOps & Infrastructure ────────────────────────────────────────────────
VER_HELM="3.17.1"
VER_TERRAFORM="1.11.0"
VER_TERRAGRUNT="1.0.0-rc3"
VER_TOFU="1.9.0"
VER_TOFU_PROVIDER="github:opentofu/opentofu"
VER_PULUMI="3.153.1"
VER_PULUMI_PROVIDER="github:pulumi/pulumi"
VER_KUBE_LINTER="0.8.1"
VER_KUBE_LINTER_PROVIDER="github:stackrox/kube-linter"
VER_TFLINT="0.61.0"
VER_TFLINT_PROVIDER="github:terraform-linters/tflint"
VER_ANSIBLE_LINT="26.1.1"
VER_ANSIBLE_LINT_PROVIDER="pipx:ansible-lint"
VER_SPECTRAL="6.15.0"
VER_SPECTRAL_PROVIDER="npm:@stoplight/spectral-cli"

# ── 📖 Documentation ──────────────────────────────────────────────────────────
VER_BATS="1.13.0"
VER_BATS_PROVIDER="npm:bats"
