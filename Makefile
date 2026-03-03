# Makefile for Snowdream Tech AI IDE Template
# This file provides a standard entry point for common development tasks.

.PHONY: help setup lint clean

# Default target
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  setup   Install necessary development tools (brew, pip, npm)"
	@echo "  lint    Run pre-commit hooks on all files"
	@echo "  clean   Clean up temporary and cache files"
	@echo "  help    Show this help message"

# Install development tools
setup:
	@echo "Installing development tools..."
	@if command -v brew >/dev/null 2>&1; then \
		brew install shellcheck actionlint hadolint shfmt gitleaks ruff clang-format; \
	else \
		echo "Warning: Homebrew not found. Please install manually: shellcheck, actionlint, hadolint, shfmt, gitleaks, ruff, clang-format"; \
	fi
	@pip3 install pre-commit yamllint
	@npm install -g markdownlint-cli2 prettier editorconfig-checker eslint @stoplight/spectral-cli @commitlint/cli @commitlint/config-conventional stylelint @taplo/cli
	@pre-commit install --hook-type pre-commit --hook-type pre-merge-commit --hook-type commit-msg

# Run pre-commit hooks
lint:
	@echo "Running pre-commit hooks..."
	@pre-commit run --all-files

# Clean up temporary and cache files
clean:
	@echo "Cleaning up..."
	@rm -rf .pytest_cache .ruff_cache .mypy_cache .coverage
	@find . -type d -name "__pycache__" -exec rm -rf {} +
	@find . -type f -name "*.pyc" -delete
	@rm -rf dist/ build/ *.egg-info
