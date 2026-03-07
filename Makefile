# Makefile for Snowdream Tech AI IDE Template
# This file provides a standard entry point for common development tasks.

# =============================================================================
# OS Detection
# =============================================================================
ifeq ($(OS),Windows_NT)
	OS_NAME := Windows
	SHELL   := powershell.exe
	.SHELLFLAGS := -NoProfile -Command
	# Colors for Windows (PowerShell handles this differently, but for echo)
	BLUE   :=
	GREEN  :=
	YELLOW :=
	RED    :=
	NC     :=
else
	OS_NAME := $(shell uname -s)
	# Colors for POSIX (using shell printf for literal escapes)
	BLUE   := $(shell printf '\033[0;34m')
	GREEN  := $(shell printf '\033[0;32m')
	YELLOW := $(shell printf '\033[1;33m')
	RED    := $(shell printf '\033[0;31m')
	NC     := $(shell printf '\033[0m')
endif

# =============================================================================
# Targets
# =============================================================================
.PHONY: all help init setup install lint format test build clean commit verify release env update audit bench docs archive-changelog check-env

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
	@echo "  $(GREEN)verify$(NC)   Run full project verification (env, lint, test)"
	@echo "  $(GREEN)release$(NC)  Standardized release manager (versioning & tagging)"
	@echo "  $(GREEN)env$(NC)      Environment configuration manager (.env)"
	@echo "  $(GREEN)docs$(NC)     Documentation site manager (dev/build/preview)"
	@echo "  $(GREEN)archive-changelog$(NC) Archive major-version changelog entries"
	@echo "  $(GREEN)check-env$(NC) Onboarding environment health check"
	@echo "  $(GREEN)update$(NC)   Update global/project tools and hooks"
	@echo "  $(GREEN)audit$(NC)    Run security audit and vulnerability scans"
	@echo "  $(GREEN)bench$(NC)    Run performance benchmarks"
	@echo "  $(GREEN)clean$(NC)    Remove temporary and generated files"
	@echo "  $(GREEN)help$(NC)     Show this help message"

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

docs:
ifeq ($(OS_NAME),Windows)
	@scripts/docs.bat $(ARGS)
else
	@sh scripts/docs.sh $(ARGS)
endif

archive-changelog:
ifeq ($(OS_NAME),Windows)
	@scripts/archive-changelog.bat
else
	@sh scripts/archive-changelog.sh
endif

check-env:
ifeq ($(OS_NAME),Windows)
	@scripts/check-env.bat
else
	@sh scripts/check-env.sh
endif

clean:
ifeq ($(OS_NAME),Windows)
	@scripts/cleanup.bat
else
	@sh scripts/cleanup.sh
endif
