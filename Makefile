# Makefile for Snowdream Tech AI IDE Template
# Purpose: Unified entry point for cross-platform project orchestration and developer governance.
# Design:
#   - POSIX-compliant shell delegation with Windows-specific Batch abstractions.
#   - Standardized lifecycle targets: init -> setup -> install -> verify -> audit.
#   - "World Class" AI documentation style (English-only technical metadata).

# =============================================================================
# Global Options
# =============================================================================
# Verbosity level: 0 (quiet), 1 (normal), 2 (verbose)
# Supports: make setup VERBOSE=2 or make setup V=2
V ?= 1
VERBOSE ?= $(V)
export VERBOSE

# Pass flags to sub-scripts
SCRIPT_ARGS :=
ifeq ($(shell [ $(VERBOSE) -ge 2 ] && echo 1),1)
	SCRIPT_ARGS += --verbose
endif
ifeq ($(shell [ $(VERBOSE) -eq 0 ] && echo 1),1)
	SCRIPT_ARGS += --quiet
endif

# =============================================================================
# OS Detection
# =============================================================================
ifeq ($(OS),Windows_NT)
	# Detect if we are running in a POSIX-like environment (Git Bash, WSL, etc.)
	# We check if 'sh' works and returns expected output.
	IS_POSIX := $(shell sh -c 'echo 1' 2>/dev/null)
	ifeq ($(IS_POSIX),1)
		OS_NAME := POSIX_WINDOWS
		# Colors for POSIX
		BLUE   := $(shell printf '\033[0;34m')
		GREEN  := $(shell printf '\033[0;32m')
		YELLOW := $(shell printf '\033[1;33m')
		RED    := $(shell printf '\033[0;31m')
		NC     := $(shell printf '\033[0m')
	else
		OS_NAME := Windows
		SHELL   := powershell.exe
		.SHELLFLAGS := -NoProfile -Command
		# Colors for native Windows (PowerShell handles this, but for make echo)
		BLUE   :=
		GREEN  :=
		YELLOW :=
		RED    :=
		NC     :=
	endif
else
	OS_NAME := $(shell uname -s)
	# Colors for POSIX
	BLUE   := $(shell printf '\033[0;34m')
	GREEN  := $(shell printf '\033[0;32m')
	YELLOW := $(shell printf '\033[1;33m')
	RED    := $(shell printf '\033[0;31m')
	NC     := $(shell printf '\033[0m')
endif

# =============================================================================
# Targets
# =============================================================================
.PHONY: all help init setup install lint format test build clean commit verify release env update audit health bench docs archive-changelog check-env sync-docs precommit

# Default target: display help
all: help

help:
	@printf "$(BLUE)Snowdream Tech AI IDE Template$(NC)\n"
	@printf "Detected OS: $(GREEN)$(OS_NAME)$(NC)\n\n"
	@printf "$(YELLOW)Usage:$(NC)\n"
	@printf "  make <target> [VARIABLE=value ...]\n\n"
	@printf "$(YELLOW)Targets:$(NC)\n"
	@printf "  $(GREEN)init$(NC)     Hydrate project from template (rename placeholders)\n"
	@echo "  $(GREEN)setup$(NC)    Install system-level development tools"
	@echo "  $(GREEN)install$(NC)  Install project-level dependencies (pip, npm)"
	@echo "  $(GREEN)lint$(NC)     Run standardized linter (pre-commit)"
	@echo "  $(GREEN)format$(NC)   Auto-format code (ruff, prettier, shfmt, etc.)"
	@echo "  $(GREEN)test$(NC)     Run unified test suite"
	@echo "  $(GREEN)build$(NC)    Build project artifacts"
	@echo "  $(GREEN)commit$(NC)   Start the interactive Commitizen CLI"
	@echo "  $(GREEN)precommit$(NC) Alias for lint (Run pre-commit hooks)"
	@echo "  $(GREEN)verify$(NC)   Run full project verification (env, lint, test)"
	@echo "  $(GREEN)release$(NC)  Standardized release manager (versioning & tagging)"
	@echo "  $(GREEN)env$(NC)      Environment configuration manager (.env)"
	@echo "  $(GREEN)docs$(NC)     Documentation site manager (dev/build/preview)"
	@echo "  $(GREEN)archive-changelog$(NC) Archive major-version changelog entries"
	@echo "  $(GREEN)check-env$(NC) Onboarding environment health check"
	@echo "  $(GREEN)update$(NC)   Update global/project tools and hooks"
	@echo "  $(GREEN)audit$(NC)    Run security audit and vulnerability scans"
	@echo "  $(GREEN)health$(NC)   Generate unified project health dashboard"
	@echo "  $(GREEN)bench$(NC)    Run performance benchmarks"
	@echo "  $(GREEN)clean$(NC)    Remove temporary and generated files"
	@echo "  $(GREEN)help$(NC)     Show this help message"

# Lifecycle Targets
init:
ifeq ($(OS_NAME),Windows)
	@scripts/init-project.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/init-project.sh $(SCRIPT_ARGS) $(ARGS)
endif

setup:
ifeq ($(OS_NAME),Windows)
	@scripts/setup.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/setup.sh $(SCRIPT_ARGS) $(ARGS)
endif

install: setup
ifeq ($(OS_NAME),Windows)
	@scripts/install.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/install.sh $(SCRIPT_ARGS) $(ARGS)
endif

lint:
ifeq ($(OS_NAME),Windows)
	@scripts/lint.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/lint.sh $(SCRIPT_ARGS) $(ARGS)
endif

precommit: lint

format:
ifeq ($(OS_NAME),Windows)
	@scripts/format.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/format.sh $(SCRIPT_ARGS) $(ARGS)
endif

test:
ifeq ($(OS_NAME),Windows)
	@scripts/test.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/test.sh $(SCRIPT_ARGS) $(ARGS)
endif

build:
ifeq ($(OS_NAME),Windows)
	@scripts/build.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/build.sh $(SCRIPT_ARGS) $(ARGS)
endif

commit:
ifeq ($(OS_NAME),Windows)
	@scripts/commit.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/commit.sh $(SCRIPT_ARGS) $(ARGS)
endif

.NOTPARALLEL: verify
verify: check-env lint test audit  ## Run full local verification (env, lint, test, audit)

release:
ifeq ($(OS_NAME),Windows)
	@scripts/release.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/release.sh $(SCRIPT_ARGS) $(ARGS)
endif

env:
ifeq ($(OS_NAME),Windows)
	@scripts/env.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/env.sh $(SCRIPT_ARGS) $(ARGS)
endif

update:
ifeq ($(OS_NAME),Windows)
	@scripts/update.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/update.sh $(SCRIPT_ARGS) $(ARGS)
endif

audit:
ifeq ($(OS_NAME),Windows)
	@scripts/audit.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/audit.sh $(SCRIPT_ARGS) $(ARGS)
endif

health:
ifeq ($(OS_NAME),Windows)
	@scripts/health.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/health.sh $(SCRIPT_ARGS) $(ARGS)
endif

bench:
ifeq ($(OS_NAME),Windows)
	@scripts/bench.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/bench.sh $(SCRIPT_ARGS) $(ARGS)
endif

sync-docs:
ifeq ($(OS_NAME),Windows)
	@scripts/sync-docs.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/sync-docs.sh $(SCRIPT_ARGS) $(ARGS)
endif

docs:
ifeq ($(OS_NAME),Windows)
	@scripts/docs.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/docs.sh $(SCRIPT_ARGS) $(ARGS)
endif

archive-changelog:
ifeq ($(OS_NAME),Windows)
	@scripts/archive-changelog.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/archive-changelog.sh $(SCRIPT_ARGS) $(ARGS)
endif

check-env:
ifeq ($(OS_NAME),Windows)
	@scripts/check-env.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/check-env.sh $(SCRIPT_ARGS) $(ARGS)
endif

clean:
ifeq ($(OS_NAME),Windows)
	@scripts/cleanup.bat $(SCRIPT_ARGS) $(ARGS)
else
	@sh scripts/cleanup.sh $(SCRIPT_ARGS) $(ARGS)
endif
