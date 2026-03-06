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
.PHONY: all help init setup install lint format test build clean commit

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

# Install project-level dependencies
install:
	@echo "$(BLUE)Installing project-level dependencies...$(RESET)"
	@$(NPM) install
	@$(VENV)/bin/pip install -r requirements-dev.txt
	@echo "$(GREEN)Dependencies installed!$(RESET)"

# Run test suite
test:
	@echo "$(BOLD)Running tests...$(RESET)"
	@echo "$(BLUE)Running bats (Shell)...$(RESET)"
	$(NPM) run test:shell
	@if command -v pwsh >/dev/null 2>&1; then \
		echo "$(BLUE)Running Pester (PowerShell)...$(RESET)"; \
		$(NPM) run test:ps; \
	fi
	@if [ -f pytest.ini ] || [ -f pyproject.toml ] || { [ -d tests ] && find tests -name "test_*.py" -o -name "*_test.py" | grep -q . ; }; then \
		echo "$(BLUE)Running pytest...$(RESET)"; \
		$(VENV)/bin/python3 -m pytest --tb=short; \
	elif [ -f go.mod ]; then \
		echo "$(BLUE)Running go test...$(RESET)"; \
		go test ./...; \
	else \
		echo "$(GREEN)Component tests finished.$(RESET)"; \
	fi
	@echo "$(GREEN)All tests passed!$(RESET)"

# Launch interactive commit CLI
commit:
	@echo "$(BOLD)Starting interactive Commitizen CLI...$(RESET)"
	$(NPM) run commit

# Build project artifacts
build:
	@echo "$(BOLD)Building project...$(RESET)"
	@if [ -f .goreleaser.yaml ] || [ -f .goreleaser.yml ]; then \
		echo "$(BLUE)Running goreleaser (snapshot)...$(RESET)"; \
		$(GORELEASER) build --snapshot --clean; \
	elif [ -f go.mod ]; then \
		echo "$(BLUE)Running go build...$(RESET)"; \
		go build ./...; \
	elif [ -f package.json ]; then \
		echo "$(BLUE)Running npm build...$(RESET)"; \
		$(NPM) run build; \
	elif [ -f pyproject.toml ]; then \
		echo "$(BLUE)Running python build...$(RESET)"; \
		$(VENV)/bin/python3 -m build; \
	else \
		echo "$(YELLOW)No build system detected. Skipping.$(RESET)"; \
	fi

# Run all pre-commit hooks
lint:
	@echo "$(BOLD)Running pre-commit hooks on all files...$(RESET)"
	@echo "$(BLUE)Pass 1/2: Applying auto-fixes...$(RESET)"
	@$(PRE_COMMIT) run --all-files || true
	@echo "$(BLUE)Pass 2/2: Verifying all checks pass...$(RESET)"
	@$(PRE_COMMIT) run --all-files
	@echo "$(GREEN)Lint complete!$(RESET)"

# Auto-format code
format:
	@echo "$(BOLD)Formatting code...$(RESET)"
	@echo "$(BLUE)Running ruff format...$(RESET)"
	$(VENV)/bin/ruff format $(RUFF_EXCLUDES) .
	@echo "$(BLUE)Running shfmt...$(RESET)"
	find . -type f -name "*.sh" $(FIND_EXCLUDES) -exec $(VENV)/bin/shfmt -w -i 2 {} +
	@echo "$(BLUE)Running prettier...$(RESET)"
	@$(NPM) exec prettier --write .
	@if [ -f go.mod ]; then \
		echo "$(BLUE)Running gofmt...$(RESET)"; \
		find . -type f -name "*.go" $(FIND_EXCLUDES) -exec gofmt -w {} +; \
	fi
	@echo "$(BLUE)Running clang-format...$(RESET)"
	find . -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.m" -o -name "*.mm" \) $(FIND_EXCLUDES) -exec $(VENV)/bin/clang-format -i {} +
	@echo "$(GREEN)Formatting complete!$(RESET)"

# Clean up temporary and generated files
clean:
	@echo "$(BOLD)Cleaning up for $(OS_NAME)...$(RESET)"
ifeq ($(OS_NAME),Windows)
	@foreach ($d in @(".pytest_cache",".ruff_cache",".mypy_cache",".coverage","dist","build")) { \
		if (Test-Path $$d) { $(RM) $$d } \
	}
	@Get-ChildItem -Path . -Filter "__pycache__" -Recurse | ForEach-Object { $(RM) $$_.FullName }
	@Get-ChildItem -Path . -Filter "*.pyc" -Recurse | ForEach-Object { $(RM) $$_.FullName }
	@Get-ChildItem -Path . -Filter "*.egg-info" -Recurse | ForEach-Object { $(RM) $$_.FullName }
else
	@$(RM) \
		.pytest_cache .ruff_cache .mypy_cache .coverage \
		dist/ build/ *.egg-info \
		coverage.xml .coverage.*
	@find . \
		-not -path "./.git/*" \
		\( -type d -name "__pycache__" \
		-o -type f -name "*.pyc" \
		-o -type f -name "*.pyo" \) \
		-exec $(RM) {} + 2>/dev/null || true
endif
	@echo "$(GREEN)Clean complete!$(RESET)"
