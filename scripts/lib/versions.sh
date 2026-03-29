#!/usr/bin/env sh
# shellcheck disable=SC2034
set -eu
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# Tool Registry - Centralized version management for dynamic registration
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
# shellcheck disable=SC2034
VER_GO="1.26.1"
VER_KOTLIN="2.3.20"
VER_RUST="1.94.1"
VER_BUN="1.3.11"
VER_DENO="2.7.9"
VER_ZIG="0.15.2"
VER_JAVA="26.0.0"
VER_DOTNET="10.0.201"
VER_RUBY="4.0.2"
VER_YARN="1.22.22"

# ── 🧪 Exotic / Domain-Specific Runtimes ─────────────────────────────────────
VER_GRAIN="0.7.2"
VER_GRAIN_PROVIDER="github:grain-lang/grain"
VER_GRAIN_REF="grain-v0.7.2"

VER_MOONBIT="0.8.3+cd28f524e"
VER_MOONBIT_PROVIDER="github:moonbitlang/moonbit-compiler"
VER_MOONBIT_REF="v0.7.2+c12686398"

VER_KCL="0.11.2"
VER_KCL_PROVIDER="github:kcl-lang/kcl"

VER_PKL="0.31.1"
VER_PKL_PROVIDER="github:apple/pkl"

VER_BAZEL="9.0.1"
VER_BAZEL_PROVIDER="github:bazelbuild/bazel"

VER_BALLERINA="2201.13.2"
VER_BALLERINA_PROVIDER="github:ballerina-platform/ballerina-distribution"

VER_STYLUA="2.4.0"
VER_STYLUA_PROVIDER="github:JohnnyMorganz/StyLua"

VER_JUST="1.48.1"
VER_JUST_PROVIDER="github:casey/just"

VER_TASK="3.49.1"
VER_TASK_PROVIDER="github:go-task/task"

VER_TYPST="0.13.0"
VER_DUCKDB="1.5.0"
# NOTE: Lychee version removed — link checking delegated to lycheeverse/lychee-action in CI.

# ── 🎨 Language Tooling (Linters/Formatters) ─────────────────────────────────
VER_KTLINT="1.16.1"
VER_KTLINT_PROVIDER="npm:@naturalcycles/ktlint"

VER_JAVA_FORMAT="1.35.0"
VER_JAVA_FORMAT_PROVIDER="github:google/google-java-format"

VER_SWIFTLINT="0.63.2"
VER_SWIFTLINT_PROVIDER="github:realm/SwiftLint"

VER_STYLELINT="17.6.0"
VER_STYLELINT_PROVIDER="npm:stylelint"

VER_STYLELINT_CONFIG="40.0.0"
VER_STYLELINT_CONFIG_PROVIDER="npm:stylelint-config-standard"

VER_ASSEMBLYSCRIPT="0.28.12"
VER_ASSEMBLYSCRIPT_PROVIDER="npm:assemblyscript"

VER_OPA="1.15.0"
VER_OPA_PROVIDER="github:open-policy-agent/opa"

VER_BUF="1.66.1"
VER_BUF_PROVIDER="github:bufbuild/buf"

VER_CUE="0.16.0"
VER_CUE_PROVIDER="github:cue-lang/cue"

VER_JSONNET="0.22.0"
VER_JSONNET_PROVIDER="github:google/go-jsonnet"

VER_GOLANGCI_LINT="1.64.5"

VER_VITEPRESS="1.6.4"
VER_VITEPRESS_PROVIDER="npm:vitepress"

VER_DOTENV_LINTER="4.0.0"
VER_DOTENV_LINTER_PROVIDER="github:dotenv-linter/dotenv-linter"

VER_CHECKMAKE="0.3.2"
VER_CHECKMAKE_PROVIDER="github:checkmake/checkmake"

# ── 🛡️ Security Scanning (CI-only by default) ─────────────────────────────────
VER_TRIVY="0.69.3"
VER_TRIVY_PROVIDER="github:aquasecurity/trivy"

VER_OSV_SCANNER="2.3.5"
VER_OSV_SCANNER_PROVIDER="github:google/osv-scanner"

VER_GOVULNCHECK="1.1.4"
VER_GOVULNCHECK_PROVIDER="go:golang.org/x/vuln/cmd/govulncheck"

VER_PIP_AUDIT="2.10.0"
VER_PIP_AUDIT_PROVIDER="pipx:pip-audit"

VER_CARGO_AUDIT="0.22.1"
VER_CARGO_AUDIT_PROVIDER="cargo:cargo-audit"

VER_ZIZMOR="1.23.1"
VER_ZIZMOR_PROVIDER="pipx:zizmor"

# ── ☁️ DevOps & Infrastructure ────────────────────────────────────────────────
VER_HELM="3.17.1"
VER_TERRAFORM="1.11.0"
VER_TERRAGRUNT="1.0.0-rc3"
VER_TOFU="1.11.5"
VER_TOFU_PROVIDER="github:opentofu/opentofu"
VER_PULUMI="3.228.0"
VER_PULUMI_PROVIDER="github:pulumi/pulumi"
VER_KUBE_LINTER="0.8.3"
VER_KUBE_LINTER_PROVIDER="github:stackrox/kube-linter"
VER_TFLINT="0.61.0"
VER_TFLINT_PROVIDER="github:terraform-linters/tflint"
VER_ANSIBLE_LINT="26.3.0"
VER_ANSIBLE_LINT_PROVIDER="pipx:ansible-lint"
VER_SPECTRAL="6.15.0"
VER_SPECTRAL_PROVIDER="npm:@stoplight/spectral-cli"

VER_GORELEASER="2.14.3"
VER_GORELEASER_PROVIDER="github:goreleaser/goreleaser"

# ── 📖 Documentation ──────────────────────────────────────────────────────────
VER_BATS="1.13.0"
VER_BATS_PROVIDER="npm:bats"
