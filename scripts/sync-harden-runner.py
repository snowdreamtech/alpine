#!/usr/bin/env python3
"""Synchronize Harden Runner endpoints across workflow files.

This script reads the centralized endpoint configuration from
.github/harden-runner-endpoints.yml and updates all workflow files
with the appropriate endpoint profiles.
"""

from pathlib import Path
from typing import Dict, List

import yaml

CONFIG_FILE = Path(".github/harden-runner-endpoints.yml")
WORKFLOWS_DIR = Path(".github/workflows")


def load_config() -> Dict:
    """Load endpoint configuration from YAML file."""
    with open(CONFIG_FILE, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def update_workflow_endpoints(filepath: Path, endpoints: List[str]) -> bool:
    """Update allowed-endpoints in a workflow file."""
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    original = content
    lines = content.split("\n")
    result = []
    indent = ""

    i = 0
    while i < len(lines):
        line = lines[i]

        # Detect allowed-endpoints section
        if "allowed-endpoints:" in line:
            result.append(line)

            # Detect indentation from next line
            if i + 1 < len(lines):
                next_line = lines[i + 1]
                if next_line.strip():
                    indent = next_line[: len(next_line) - len(next_line.lstrip())]

            # Add new endpoints
            for endpoint in endpoints:
                result.append(f"{indent}{endpoint}")

            # Skip old endpoints
            i += 1
            while i < len(lines):
                if lines[i] and not lines[i].startswith(" "):
                    # Reached next section
                    break
                i += 1

            continue

        result.append(line)
        i += 1

    new_content = "\n".join(result)

    if new_content != original:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(new_content)
        return True
    return False


def main():
    """Main synchronization logic."""
    print("📋 Synchronizing Harden Runner endpoints...")
    print()

    # Load configuration
    try:
        config = load_config()
    except FileNotFoundError:
        print(f"❌ Error: Configuration file {CONFIG_FILE} not found")
        return 1
    except yaml.YAMLError as e:
        print(f"❌ Error parsing YAML: {e}")
        return 1

    workflow_profiles = config.get("workflow_profiles", {})
    updated_count = 0

    # Process each workflow
    for workflow_name, profile_name in workflow_profiles.items():
        workflow_path = WORKFLOWS_DIR / workflow_name

        if not workflow_path.exists():
            print(f"⚠️  Warning: {workflow_name} not found")
            continue

        # Get endpoints for this profile
        endpoints = config.get(profile_name, [])
        if not endpoints:
            print(f"⚠️  Warning: Profile '{profile_name}' not found for {workflow_name}")
            continue

        # Update workflow
        if update_workflow_endpoints(workflow_path, endpoints):
            print(f"✓ Updated: {workflow_name} (profile: {profile_name}, {len(endpoints)} endpoints)")
            updated_count += 1
        else:
            print(f"- Skipped: {workflow_name} (no changes)")

    print()
    print(f"📊 Summary: {updated_count} files updated")
    print()
    print("💡 Tip: Review changes with 'git diff .github/workflows/'")

    return 0


if __name__ == "__main__":
    exit(main())
