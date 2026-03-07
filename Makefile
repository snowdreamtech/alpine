# Makefile for Snowdream Tech AI IDE Template
# This file provides a standard entry point for common development tasks.

# =============================================================================
# OS Detection
# =============================================================================
ifeq ($(OS),Windows_NT)
	OS_NAME := Windows
	SHELL   := powershell.exe
	.SHELLFLAGS := -NoProfile -Command
else
	OS_NAME := $(shell uname -s)
endif

# =============================================================================
# Targets
# =============================================================================
.PHONY: all help init setup install lint format test build clean commit verify release env update audit bench

# Default target: display help
all: help

help:
	@echo "Snowdream Tech AI IDE Template"
	@echo "Detected OS: $(OS_NAME)"
	@echo ""
	@echo "Usage:"
	@echo "  make <target> [VARIABLE=value ...]"
	@echo ""
	@echo "Targets:"
	@echo "  init     Hydrate project from template (rename placeholders)"
	@echo "  setup    Install system-level development tools"
	@echo "  install  Install project-level dependencies (pip, npm)"
	@echo "  lint     Run standardized linter (pre-commit)"
	@echo "  format   Auto-format code (ruff, prettier, shfmt, etc.)"
	@echo "  test     Run unified test suite"
	@echo "  build    Build project artifacts"
	@echo "  commit   Start the interactive Commitizen CLI"
	@echo "  verify   Run full project verification (env, lint, test)"
	@echo "  release  Standardized release manager (versioning & tagging)"
	@echo "  env      Environment configuration manager (.env)"
	@echo "  clean    Remove temporary and generated files"
	@echo "  help     Show this help message"

# Lifecycle Targets
init:
ifeq ($(OS_NAME),Windows)
	@scripts/init-project.bat
else
	@sh scripts/init-project.sh
endif

setup:
ifeq ($(OS_NAME),Windows)
	@scripts/setup.bat
else
	@sh scripts/setup.sh
endif

install:
ifeq ($(OS_NAME),Windows)
	@scripts/install.bat
else
	@sh scripts/install.sh
endif

lint:
ifeq ($(OS_NAME),Windows)
	@scripts/lint.bat
else
	@sh scripts/lint.sh
endif

format:
ifeq ($(OS_NAME),Windows)
	@scripts/format.bat
else
	@sh scripts/format.sh
endif

test:
ifeq ($(OS_NAME),Windows)
	@scripts/test.bat
else
	@sh scripts/test.sh
endif

build:
ifeq ($(OS_NAME),Windows)
	@scripts/build.bat
else
	@sh scripts/build.sh
endif

commit:
ifeq ($(OS_NAME),Windows)
	@scripts/commit.bat
else
	@sh scripts/commit.sh
endif

verify:
ifeq ($(OS_NAME),Windows)
	@scripts/verify.bat
else
	@sh scripts/verify.sh
endif

release:
ifeq ($(OS_NAME),Windows)
	@scripts/release.bat
else
	@sh scripts/release.sh
endif

env:
ifeq ($(OS_NAME),Windows)
	@scripts/env.bat
else
	@sh scripts/env.sh
endif

update:
ifeq ($(OS_NAME),Windows)
	@scripts/update.bat
else
	@sh scripts/update.sh
endif

audit:
ifeq ($(OS_NAME),Windows)
	@scripts/audit.bat
else
	@sh scripts/audit.sh
endif

bench:
ifeq ($(OS_NAME),Windows)
	@scripts/bench.bat
else
	@sh scripts/bench.sh
endif

clean:
ifeq ($(OS_NAME),Windows)
	@scripts/cleanup.bat
else
	@sh scripts/cleanup.sh
endif
