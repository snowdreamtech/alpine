# Makefile for Snowdream Tech AI IDE Template
# This file provides a standard entry point for common development tasks.

# =============================================================================
# OS Detection
# =============================================================================
ifeq ($(OS),Windows_NT)
	OS_NAME := Windows
	SHELL   := powershell.exe
	.SHELLFLAGS := -NoProfile -Command
	RM    := Remove-Item -Recurse -Force
	MKDIR := New-Item -ItemType Directory -Force
else
	OS_NAME := $(shell uname -s)
	RM    := rm -rf
	MKDIR := mkdir -p
endif

# Directories to exclude from search operations (mirrors CI ignore list)
PRUNE_DIRS := .git .ansible node_modules .venv venv env vendor dist build out target \
	.next .nuxt .output __pycache__ .specify

FIND_EXCLUDES := $(foreach dir,$(PRUNE_DIRS),-not -path "*/$(dir)/*" -not -path "*/$(dir)")
RUFF_EXCLUDES := $(foreach dir,$(PRUNE_DIRS),--exclude $(dir))

# =============================================================================
# Tool Variables (can be overridden: make setup PYTHON=python3.11)
# =============================================================================
PYTHON     ?= python3
VENV       ?= .venv
PIP        ?= $(VENV)/bin/pip3
NODE       ?= node
NPM        ?= pnpm
PRE_COMMIT ?= $(VENV)/bin/pre-commit
GORELEASER ?= goreleaser
GITHUB_PROXY ?= https://gh-proxy.sn0wdr1am.com/

# =============================================================================
# Color Output (disable with: make NO_COLOR=1 <target>)
# =============================================================================
ifndef NO_COLOR
	RED    := \033[0;31m
	GREEN  := \033[0;32m
	YELLOW := \033[0;33m
	BLUE   := \033[0;34m
	BOLD   := \033[1m
	RESET  := \033[0m
else
	RED    :=
	GREEN  :=
	YELLOW :=
	BLUE   :=
	BOLD   :=
	RESET  :=
endif

# =============================================================================
# Targets
# =============================================================================
.PHONY: all help init setup install lint format test build clean commit verify release env

# Default target: display help
all: help

help:
	@echo "$(BOLD)Snowdream Tech AI IDE Template$(RESET)"
	@echo "$(BLUE)Detected OS: $(OS_NAME)$(RESET)"
	@echo ""
	@echo "$(BOLD)Usage:$(RESET)"
	@echo "  make $(YELLOW)<target>$(RESET) [VARIABLE=value ...]"
	@echo ""
	@echo "$(BOLD)Targets:$(RESET)"
	@echo "  $(GREEN)init$(RESET)     Hydrate project from template (rename placeholders)"
	@echo "  $(GREEN)setup$(RESET)    Install system-level development tools"
	@echo "  $(GREEN)install$(RESET)  Install project-level dependencies (pip, npm)"
	@echo "  $(GREEN)lint$(RESET)     Run all pre-commit hooks on all files"
	@echo "  $(GREEN)format$(RESET)   Auto-format code (ruff, prettier, shfmt, etc.)"
	@echo "  $(GREEN)test$(RESET)     Run test suite"
	@echo "  $(GREEN)build$(RESET)    Build project artifacts"
	@echo "  $(GREEN)commit$(RESET)   Start the interactive Commitizen CLI to create a structured commit"
	@echo "  $(GREEN)clean$(RESET)    Remove temporary and generated files"
	@echo "  $(GREEN)help$(RESET)     Show this help message"
	@echo ""
	@echo "$(BOLD)Overridable Variables:$(RESET)"
	@echo "  PYTHON=$(PYTHON)  PIP=$(PIP)  NODE=$(NODE)  NPM=$(NPM)"
	@echo "  NO_COLOR=1    Disable colored output"

# Hydrate project from template
init:
ifeq ($(OS_NAME),Windows)
	@powershell -ExecutionPolicy Bypass -File scripts/init-project.ps1
else
	@sh scripts/init-project.sh
endif

setup:
ifeq ($(OS_NAME),Windows)
	@powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
else
	@sh scripts/setup.sh
endif
	@echo "$(BLUE)Installing project-level dependencies...$(RESET)"
	@$(MAKE) install
	@echo "$(GREEN)Setup complete!$(RESET)"

# Archive major version changelogs
archive-changelog:
	@echo "$(BLUE)Archiving previous major version changelogs...$(RESET)"
ifeq ($(OS_NAME),Windows)
	@scripts/archive-changelog.bat
else
	@sh scripts/archive-changelog.sh
endif
	@echo "$(GREEN)Archiving complete!$(RESET)"

# Install project-level dependencies
install:
	@echo "$(BLUE)Installing project-level dependencies...$(RESET)"
	@$(NPM) install
	@$(VENV)/bin/pip install -r requirements-dev.txt
	@echo "$(GREEN)Dependencies installed!$(RESET)"

# Run test suite
test:
ifeq ($(OS_NAME),Windows)
	@scripts/test.bat
else
	@sh scripts/test.sh
endif

# Launch interactive commit CLI
commit:
ifeq ($(OS_NAME),Windows)
	@scripts/commit.bat
else
	@sh scripts/commit.sh
endif

# Build project artifacts
build:
ifeq ($(OS_NAME),Windows)
	@scripts/build.bat
else
	@sh scripts/build.sh
endif

# Run all pre-commit hooks
lint:
ifeq ($(OS_NAME),Windows)
	@scripts/lint.bat
else
	@sh scripts/lint.sh
endif

# Auto-format code
format:
ifeq ($(OS_NAME),Windows)
	@scripts/format.bat
else
	@sh scripts/format.sh
endif

# Clean up temporary and generated files
clean:
ifeq ($(OS_NAME),Windows)
	@scripts/cleanup.bat
else
	@sh scripts/cleanup.sh
endif

# Full project verification
verify:
ifeq ($(OS_NAME),Windows)
	@scripts/verify.bat
else
	@sh scripts/verify.sh
endif

# Release manager
release:
ifeq ($(OS_NAME),Windows)
	@scripts/release.bat
else
	@sh scripts/release.sh
endif

# Environment manager
env:
ifeq ($(OS_NAME),Windows)
	@scripts/env.bat
else
	@sh scripts/env.sh
endif
