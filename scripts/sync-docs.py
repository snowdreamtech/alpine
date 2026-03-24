#!/usr/bin/env python3
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# scripts/sync-docs.py - Documentation Bridge Generator
#
# Purpose:
#   Synchronizes project rules and workflows with the VitePress documentation site.
#   Generates "bridge" files that link documentation pages to their source rule files.
#
# Usage:
#   python3 scripts/sync-docs.py
#
# Standards:
#   - Python 3.10+ compatible.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 03 (Architecture).
#
# Features:
#   - Automated metadata extraction (titles, objectives, sections).
#   - Intelligent category mapping for rules.
#   - VitePress-optimized Markdown generation.

import os
import re
from pathlib import Path

# Configuration
REPO_ROOT = Path(__file__).parent.parent
AGENT_DIR = REPO_ROOT / ".agent"
DOCS_DIR = REPO_ROOT / "docs"

RULES_SRC = AGENT_DIR / "rules"
WORKFLOWS_SRC = AGENT_DIR / "workflows"

RULES_DEST = DOCS_DIR / "rules"
WORKFLOWS_DEST = DOCS_DIR / "workflows"

# Mapping for special categories in rules
RULE_CATEGORIES = {
    "languages": RULES_DEST / "languages",
    "frontend": RULES_DEST / "frontend",
    "backend": RULES_DEST / "backend",
    "database": RULES_DEST / "database",
    "infrastructure": RULES_DEST / "infrastructure",
    "specialized": RULES_DEST / "specialized",
}


def extract_metadata(file_path):
    """
    Extracts title, objective, and top-level sections (##) from a markdown file.

    Args:
        file_path (Path): Path to the markdown source file.

    Returns:
        tuple[str, str, list[str]]: Title, Objective string, and list of section titles.
    """
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Extract title
    title_match = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
    title = title_match.group(1) if title_match else file_path.stem.capitalize()

    # Extract objective/description
    obj_match = re.search(r"^>\s*Objective:\s*(.+)$", content, re.MULTILINE)
    objective = obj_match.group(1) if obj_match else ""

    # Extract top-level sections (##)
    sections = re.findall(r"^##\s+(\d+\.\s+.+)$", content, re.MULTILINE)

    return title, objective, sections


def create_bridge_file(dest_path, source_rel_path, title, objective, sections):
    """
    Generates a VitePress-compatible bridge file linking to the source rules or workflows.

    Args:
        dest_path (Path): Path where the bridge file should be created.
        source_rel_path (str): Relative path to the source file within the repo.
        title (str): The extracted title of the rule/workflow.
        objective (str): The extracted objective/description.
        sections (list[str]): List of top-level sections within the file.
    """
    os.makedirs(dest_path.parent, exist_ok=True)

    repo_url = f"https://github.com/snowdreamtech/template/blob/main/{source_rel_path}"

    content = f"# {title}\n\n"
    if objective:
        content += f"> Objective: {objective}\n\n"

    content += "::: tip Source File\n"
    content += f"View the full rule: [`{source_rel_path}`]({repo_url})\n"
    content += ":::\n\n"

    if sections:
        content += "## Sections\n\n"
        for section in sections:
            content += f"- {section}\n"
        content += "\n"

    with open(dest_path, "w", encoding="utf-8") as f:
        f.write(content)


def sync_rules():
    """
    Orchestrates the synchronization of project rules from .agent/rules to docs/rules.
    Handles category mapping and bridge file generation.
    """
    print("Syncing rules...")
    for rule_file in RULES_SRC.glob("*.md"):
        # Skip numbering for core rules to handle them specifically if needed
        # but for now, we process all.

        # Decide destination based on filename or existing structure
        # This is a bit simplified; in reality, we might need a more robust mapping.
        # For now, if it's already in a subfolder in docs/rules, we keep it there.

        rel_path = f".agent/rules/{rule_file.name}"
        title, objective, sections = extract_metadata(rule_file)

        # Check if it belongs to a category
        target_dir = RULES_DEST
        # Simple heuristic: check if it already exists in a category subdir
        found = False
        for cat, path in RULE_CATEGORIES.items():
            if (path / rule_file.name).exists():
                target_dir = path
                found = True
                break

        if not found:
            # Fallback for core rules (01-12)
            if re.match(r"^\d+", rule_file.name):
                target_dir = RULES_DEST
            else:
                # Default to specialized if unknown
                target_dir = RULE_CATEGORIES["specialized"]

        dest_path = target_dir / rule_file.name
        create_bridge_file(dest_path, rel_path, title, objective, sections)
        print(f"  -> {dest_path.relative_to(REPO_ROOT)}")


def sync_workflows():
    """
    Orchestrates the synchronization of project workflows from .agent/workflows to docs/workflows.
    """
    print("Syncing workflows...")
    for wf_file in WORKFLOWS_SRC.glob("*.md"):
        rel_path = f".agent/workflows/{wf_file.name}"
        title, objective, sections = extract_metadata(wf_file)
        dest_path = WORKFLOWS_DEST / wf_file.name
        create_bridge_file(dest_path, rel_path, title, objective, sections)
        print(f"  -> {dest_path.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    sync_rules()
    sync_workflows()
    print("\n✨ Sync complete!")
