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
PRUNE_DIRS := .git node_modules .venv venv env vendor dist build out target \
	.next .nuxt .output __pycache__ .specify

FIND_EXCLUDES := $(foreach dir,$(PRUNE_DIRS),-not -path "*/$(dir)/*" -not -path "*/$(dir)")
RUFF_EXCLUDES := $(foreach dir,$(PRUNE_DIRS),--exclude $(dir))

# =============================================================================
# Tool Variables (can be overridden: make setup PYTHON=python3.11)
# =============================================================================
PYTHON     ?= python3
PIP        ?= pip3
NODE       ?= node
NPM        ?= npm
PRE_COMMIT ?= pre-commit
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
.PHONY: all help init setup install lint format test build check clean

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
	@echo "  $(GREEN)check$(RESET)    Run security and dependency audit checks"
	@echo "  $(GREEN)clean$(RESET)    Remove temporary and generated files"
	@echo "  $(GREEN)help$(RESET)     Show this help message"
	@echo ""
	@echo "$(BOLD)Overridable Variables:$(RESET)"
	@echo "  PYTHON=$(PYTHON)  PIP=$(PIP)  NODE=$(NODE)  NPM=$(NPM)"
	@echo "  NO_COLOR=1    Disable colored output"

# Hydrate project from template
init:
	@bash scripts/init-project.sh

# Install system-level development tools based on OS and package manager
setup:
	@echo "$(BOLD)Installing system tools for $(OS_NAME)...$(RESET)"
ifeq ($(OS_NAME),Darwin)
	@if command -v brew >/dev/null 2>&1; then \
		echo "$(BLUE)Detected Homebrew. Installing tools...$(RESET)"; \
		brew install shellcheck actionlint hadolint shfmt gitleaks ruff clang-format \
			dotenv-linter golangci-lint checkmake tflint kube-linter ktlint; \
	elif command -v port >/dev/null 2>&1; then \
		echo "$(BLUE)Detected MacPorts. Installing tools...$(RESET)"; \
		sudo port install shellcheck actionlint hadolint shfmt gitleaks ruff clang-18; \
		sudo port select --set clang mp-clang-18; \
		curl -fLsS $(GITHUB_PROXY)https://raw.githubusercontent.com/dotenv-linter/dotenv-linter/master/install.sh | sh -s -- -b ~/.local/bin; \
		curl -fLsS $(GITHUB_PROXY)https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b ~/.local/bin; \
		curl -fLsS $(GITHUB_PROXY)https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash | bash -s -- latest ~/.local/bin; \
	else \
		echo "$(RED)Error: Neither Homebrew nor MacPorts found. Please install one first.$(RESET)"; exit 1; \
	fi
else ifeq ($(OS_NAME),Linux)
	@if command -v apt-get >/dev/null 2>&1; then \
		echo "$(BLUE)Detected APT. Installing tools...$(RESET)"; \
		sudo apt-get update && sudo apt-get install -y \
			shellcheck hadolint shfmt gitleaks python3-ruff clang-format ktlint; \
		$(PIP) install actionlint-py; \
		curl -fLsS $(GITHUB_PROXY)https://raw.githubusercontent.com/dotenv-linter/dotenv-linter/master/install.sh | sh -s -- -b ~/.local/bin; \
		curl -fLsS $(GITHUB_PROXY)https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b ~/.local/bin; \
		curl -fLsS $(GITHUB_PROXY)https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash; \
		curl -fLsS $(GITHUB_PROXY)https://github.com/stackrox/kube-linter/releases/latest/download/kube-linter-linux.tar.gz | tar -xz -C ~/.local/bin kube-linter; \
		GO_CHECKMAKE_URL=$$(curl -sSf https://api.github.com/repos/checkmake/checkmake/releases/latest | grep 'browser_download_url.*linux.*amd64' | head -1 | cut -d'"' -f4); \
		curl -fLsS "$(GITHUB_PROXY)$$GO_CHECKMAKE_URL" -o ~/.local/bin/checkmake && chmod +x ~/.local/bin/checkmake; \
	elif command -v dnf >/dev/null 2>&1; then \
		echo "$(BLUE)Detected DNF. Installing tools...$(RESET)"; \
		sudo dnf install -y shellcheck hadolint shfmt gitleaks ruff clang-format ktlint; \
		$(PIP) install actionlint-py; \
		curl -fLsS $(GITHUB_PROXY)https://raw.githubusercontent.com/dotenv-linter/dotenv-linter/master/install.sh | sh -s -- -b ~/.local/bin; \
		curl -fLsS $(GITHUB_PROXY)https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b ~/.local/bin; \
		curl -fLsS $(GITHUB_PROXY)https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash; \
		curl -fLsS $(GITHUB_PROXY)https://github.com/stackrox/kube-linter/releases/latest/download/kube-linter-linux.tar.gz | tar -xz -C ~/.local/bin kube-linter; \
	elif command -v apk >/dev/null 2>&1; then \
		echo "$(BLUE)Detected APK. Installing tools...$(RESET)"; \
		sudo apk add shellcheck actionlint hadolint shfmt gitleaks py3-ruff ktlint; \
		curl -fLsS $(GITHUB_PROXY)https://raw.githubusercontent.com/dotenv-linter/dotenv-linter/master/install.sh | sh -s -- -b ~/.local/bin; \
		curl -fLsS $(GITHUB_PROXY)https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b ~/.local/bin; \
	else \
		echo "$(RED)Error: Unsupported Linux package manager.$(RESET)"; exit 1; \
	fi
else ifeq ($(OS_NAME),Windows)
	@Write-Host "Installing system tools for Windows..." -ForegroundColor Blue
	@if (Get-Command scoop -ErrorAction SilentlyContinue) { \
		scoop install shellcheck actionlint hadolint shfmt gitleaks llvm \
			golangci-lint tflint kube-linter checkmake ktlint dotenv-linter; \
	} elseif (Get-Command choco -ErrorAction SilentlyContinue) { \
		choco install shellcheck actionlint hadolint shfmt gitleaks llvm \
			golangci-lint tflint ktlint --yes; \
		Invoke-WebRequest -Uri '$(GITHUB_PROXY)https://raw.githubusercontent.com/dotenv-linter/dotenv-linter/master/install.sh' -OutFile install.sh; sh install.sh -b "$$env:LOCALAPPDATA\Microsoft\WinGet\Packages"; Remove-Item install.sh; \
	} elseif (Get-Command winget -ErrorAction SilentlyContinue) { \
		winget install --id koalaman.shellcheck rhysd.actionlint hadolint.hadolint mvdan.sh \
			GolangCI.golangci-lint terraform-linters.tflint --silent; \
	} else { \
		Write-Host "Error: No supported package manager found (Scoop/Choco/Winget)." -ForegroundColor Red; exit 1; \
	}
endif
	@$(PIP) install pre-commit yamllint sqlfluff
	@$(NPM) install -g markdownlint-cli2 prettier editorconfig-checker eslint \
		@stoplight/spectral-cli @commitlint/cli @commitlint/config-conventional \
		stylelint stylelint-config-standard @taplo/cli sort-package-json
	@$(PRE_COMMIT) install \
		--hook-type pre-commit \
		--hook-type pre-merge-commit \
		--hook-type commit-msg
	@echo "$(GREEN)Setup complete!$(RESET)"

# Install project-level dependencies
install:
	@echo "$(BOLD)Installing project dependencies...$(RESET)"
	@if [ -f requirements.txt ]; then \
		echo "$(BLUE)Installing Python dependencies...$(RESET)"; \
		$(PIP) install -r requirements.txt; \
	fi
	@if [ -f requirements-dev.txt ]; then \
		$(PIP) install -r requirements-dev.txt; \
	fi
	@if [ -f package.json ]; then \
		echo "$(BLUE)Installing Node.js dependencies...$(RESET)"; \
		$(NPM) install; \
	fi
	@if [ -f go.mod ]; then \
		echo "$(BLUE)Downloading Go modules...$(RESET)"; \
		go mod download; \
	fi
	@echo "$(GREEN)Dependencies installed!$(RESET)"

# Run all pre-commit hooks
# First pass: let hooks auto-fix files (whitespace, formatting, etc.)
# Second pass: verify no issues remain after fixes
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
	@if command -v ruff >/dev/null 2>&1; then \
		echo "$(BLUE)Running ruff format...$(RESET)"; \
		ruff format $(RUFF_EXCLUDES) .; \
	fi
	@if command -v shfmt >/dev/null 2>&1; then \
		echo "$(BLUE)Running shfmt...$(RESET)"; \
		find . -type f -name "*.sh" $(FIND_EXCLUDES) -exec shfmt -w -i 2 {} +; \
	fi
	@if command -v prettier >/dev/null 2>&1; then \
		echo "$(BLUE)Running prettier...$(RESET)"; \
		prettier --write .; \
	fi
	@if command -v gofmt >/dev/null 2>&1 && [ -f go.mod ]; then \
		echo "$(BLUE)Running gofmt...$(RESET)"; \
		find . -type f -name "*.go" $(FIND_EXCLUDES) -exec gofmt -w {} +; \
	fi
	@echo "$(GREEN)Formatting complete!$(RESET)"

# Run tests
test:
	@echo "$(BOLD)Running tests...$(RESET)"
	@if [ -f pytest.ini ] || [ -f pyproject.toml ] || [ -d tests ]; then \
		echo "$(BLUE)Running pytest...$(RESET)"; \
		$(PYTHON) -m pytest --tb=short; \
	elif [ -f go.mod ]; then \
		echo "$(BLUE)Running go test...$(RESET)"; \
		go test ./...; \
	elif [ -f package.json ]; then \
		echo "$(BLUE)Running npm test...$(RESET)"; \
		$(NPM) test; \
	else \
		echo "$(YELLOW)No test runner detected. Skipping.$(RESET)"; \
	fi

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
		$(PYTHON) -m build; \
	else \
		echo "$(YELLOW)No build system detected. Skipping.$(RESET)"; \
	fi

# Security and dependency audit
check:
	@echo "$(BOLD)Running security and dependency checks...$(RESET)"
	@if command -v gitleaks >/dev/null 2>&1; then \
		echo "$(BLUE)Checking for secrets with gitleaks...$(RESET)"; \
		gitleaks detect --source . --no-git; \
	fi
	@if command -v ruff >/dev/null 2>&1 && ([ -f pyproject.toml ] || find . -type f -name "*.py" $(FIND_EXCLUDES) | grep -q .); then \
		echo "$(BLUE)Checking Python code with ruff...$(RESET)"; \
		ruff check $(RUFF_EXCLUDES) .; \
	fi
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "$(BLUE)Checking shell scripts with shellcheck...$(RESET)"; \
		find . -type f -name "*.sh" $(FIND_EXCLUDES) \
			-exec shellcheck {} +; \
	fi
	@if [ -f go.mod ] && command -v govulncheck >/dev/null 2>&1; then \
		echo "$(BLUE)Checking Go vulnerabilities with govulncheck...$(RESET)"; \
		govulncheck ./...; \
	fi
	@echo "$(GREEN)Security check complete!$(RESET)"

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
