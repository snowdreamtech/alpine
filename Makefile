# Makefile for Snowdream Tech AI IDE Template
# This file provides a standard entry point for common development tasks.

# OS detection
ifeq ($(OS),Windows_NT)
	OS_NAME := Windows
	SHELL := powershell.exe
	.SHELLFLAGS := -NoProfile -Command
	RM := Remove-Item -Recurse -Force
	MKDIR := New-Item -ItemType Directory -Force
else
	OS_NAME := $(shell uname -s)
	RM := rm -rf
	MKDIR := mkdir -p
endif

.PHONY: help setup lint clean

# Default target
help:
	@echo "Detected OS: $(OS_NAME)"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  setup   Install necessary development tools (Homebrew/MacPorts/APT/DNF/APK)"
	@echo "  lint    Run pre-commit hooks on all files"
	@echo "  clean   Clean up temporary and cache files"
	@echo "  help    Show this help message"

# Install development tools based on OS and package manager
setup:
	@echo "Installing development tools for $(OS_NAME)..."
ifeq ($(OS_NAME),Darwin)
	@if command -v port >/dev/null 2>&1; then \
		echo "Detected MacPorts. Installing tools..."; \
		sudo port install shellcheck github-actionlint hadolint shfmt gitleaks ruff clang-format-18; \
	elif command -v brew >/dev/null 2>&1; then \
		echo "Detected Homebrew. Installing tools..."; \
		brew install shellcheck actionlint hadolint shfmt gitleaks ruff clang-format; \
	else \
		echo "Error: Neither Homebrew nor MacPorts found."; exit 1; \
	fi
else ifeq ($(OS_NAME),Linux)
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y shellcheck actionlint hadolint shfmt gitleaks python3-ruff clang-format; \
	elif command -v dnf >/dev/null 2>&1; then \
		sudo dnf install -y shellcheck actionlint hadolint shfmt gitleaks ruff clang-format; \
	elif command -v apk >/dev/null 2>&1; then \
		sudo apk add shellcheck actionlint hadolint shfmt gitleaks ruff clang-format; \
	fi
else ifeq ($(OS_NAME),Windows)
	@echo "Please ensure you have scoop or choco installed to manage these binaries."
	@if (Get-Command scoop -ErrorAction SilentlyContinue) { \
		scoop install shellcheck actionlint hadolint shfmt gitleaks ruff clang-format; \
	} else if (Get-Command choco -ErrorAction SilentlyContinue) { \
		choco install shellcheck actionlint hadolint shfmt gitleaks ruff clang-format; \
	}
endif
	@pip3 install pre-commit yamllint
	@npm install -g markdownlint-cli2 prettier editorconfig-checker eslint @stoplight/spectral-cli @commitlint/cli @commitlint/config-conventional stylelint @taplo/cli
	@pre-commit install --hook-type pre-commit --hook-type pre-merge-commit --hook-type commit-msg

# Run pre-commit hooks
lint:
	@echo "Running pre-commit hooks..."
	@pre-commit run --all-files

# Clean up temporary and cache files
clean:
	@echo "Cleaning up for $(OS_NAME)..."
ifeq ($(OS_NAME),Windows)
	@if (Test-Path .pytest_cache) { $(RM) .pytest_cache }
	@if (Test-Path .ruff_cache) { $(RM) .ruff_cache }
	@if (Test-Path .mypy_cache) { $(RM) .mypy_cache }
	@if (Test-Path .coverage) { $(RM) .coverage }
	@Get-ChildItem -Path . -Filter "__pycache__" -Recurse | ForEach-Object { $(RM) $_.FullName }
	@Get-ChildItem -Path . -Filter "*.pyc" -Recurse | ForEach-Object { $(RM) $_.FullName }
	@if (Test-Path dist) { $(RM) dist }
	@if (Test-Path build) { $(RM) build }
else
	@$(RM) .pytest_cache .ruff_cache .mypy_cache .coverage
	@find . -type d -name "__pycache__" -exec $(RM) {} +
	@find . -type f -name "*.pyc" -delete
	@$(RM) dist/ build/ *.egg-info
endif
