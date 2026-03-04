#!/bin/bash

# --- Rule Topology Manager ---
# Synchronizes core rules from .agent/rules/ to various AI IDE configuration files.
# Ensures that all AI tools follow the same Single Source of Truth (SSoT).
#
# Supported IDEs: Cursor, Windsurf, Cline, Roo Code, Aide.

set -euo pipefail

RULES_DIR=".agent/rules"

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔄 Synchronizing AI IDE Rules...${NC}"

if [ ! -d "$RULES_DIR" ]; then
  echo -e "${RED}❌ Error: Core rules directory '$RULES_DIR' not found.${NC}"
  exit 1
fi

# Fetch and sort all rule files
RULE_FILES=$(find "$RULES_DIR" -maxdepth 1 -name "*.md" | sort)
if [ -z "$RULE_FILES" ]; then
  echo -e "${YELLOW}⚠️ Warning: No rule files found in '$RULES_DIR'.${NC}"
  exit 0
fi

# Function to generate the redirect content
generate_rules_content() {
  local ide_name="$1"
  cat <<EOF
# 🚨 CRITICAL AI INSTRUCTION: $ide_name 🚨

> [!IMPORTANT]
> This project uses a Unified Rule System (Single Source of Truth).
> You MUST strictly adhere to the rules defined in the central directory.

**Source**: \`$RULES_DIR/\`

## 📜 Execution Order
$(for f in $RULE_FILES; do echo " - $f"; done)

---
*Synchronized via \`make sync-rules\`. Do not edit directly.*
EOF
}

# List of IDE configuration files and their display names
# Format: "filename|IDE Name"
SYNC_TARGETS=(
  ".cursorrules|Cursor"
  ".windsurfrules|Windsurf"
  ".clinerules|Cline"
  ".roorules|Roo Code"
  ".aide/rules.md|Aide"
)

# Create/Update each IDE file
for target in "${SYNC_TARGETS[@]}"; do
  FILE="${target%%|*}"
  NAME="${target##*|}"

  mkdir -p "$(dirname "$FILE")"
  generate_rules_content "$NAME" >"$FILE"
  echo -e "  ${GREEN}✅ Updated: ${BLUE}$FILE${NC} ($NAME)"
done

echo -e "\n${GREEN}✨ Rules synchronization complete!${NC}"
