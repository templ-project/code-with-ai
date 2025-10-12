#!/usr/bin/env python3
"""Create feature command for CwAI CLI."""

import asyncio
import json
import os
import shutil
import sys
from pathlib import Path
from typing import List, Optional

import click

import sys
from pathlib import Path
# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from utils.helpers_py import (
    detect_feature_name,
    extract_feature_id,
    get_repo_root,
    git_branch_exists,
    git_checkout,
    load_environment,
    output_results,
    padd_feature_id,
    parse_labels,
    requirement_to_title,
    title_to_slug,
)
from utils.issue_manager_py import get_issue_manager
from utils.logger_py import log_error, log_info, log_warn


async def create_feature_command_async(
    requirement: str,
    output_json: bool,
    title: str,
    templates: List[str],
    labels: List[str],
) -> None:
    """Main create feature command (async version)."""
    repo_root = get_repo_root()
    load_environment(repo_root)

    if not requirement:
        log_error("Requirement is required. Provide the requirement as arguments.")

    specs_folder = os.environ.get("CWAI_SPECS_FOLDER")
    issue_manager_type = os.environ.get("CWAI_ISSUE_MANAGER")

    if not specs_folder:
        log_error("Environment variable CWAI_SPECS_FOLDER is required")
    if not issue_manager_type:
        log_error("Environment variable CWAI_ISSUE_MANAGER is required")

    # Detect if this is an existing feature or new
    feature_name = detect_feature_name(requirement)

    if feature_name:
        log_info(f"Detected existing feature reference: {feature_name}")
        await update_existing_feature(
            feature_name,
            labels,
            requirement,
            templates,
            output_json,
            specs_folder,
            issue_manager_type,
        )
    else:
        log_info("No existing feature reference found; creating new feature")
        await create_new_feature(
            requirement,
            title,
            labels,
            templates,
            output_json,
            specs_folder,
            issue_manager_type,
            repo_root,
        )


async def create_new_feature(
    requirement: str,
    title: str,
    labels: List[str],
    templates: List[str],
    output_json: bool,
    specs_folder: str,
    issue_manager_type: str,
    repo_root: Path,
) -> None:
    """Create a new feature."""
    feature_title = title or requirement_to_title(requirement)
    feature_slug = title_to_slug(feature_title)
    feature_parent_dir = repo_root / specs_folder

    feature_parent_dir.mkdir(parents=True, exist_ok=True)

    issue_manager = get_issue_manager(issue_manager_type)
    feature_id = await issue_manager.create_issue(
        feature_slug,
        feature_title,
        feature_parent_dir,
        labels,
        requirement,
    )

    feature_padded_id = padd_feature_id(feature_id)
    feature_name = f"{feature_padded_id}-{feature_slug}"
    feature_dir = feature_parent_dir / feature_name

    log_info(f"🚀 Created feature: {feature_name}")

    # Create branch (or switch to it if it already exists)
    try:
        branch_exists = await git_branch_exists(feature_name)
        if branch_exists:
            await git_checkout(feature_name, create=False)
            log_info(f"Switched to existing branch: {feature_name}")
        else:
            await git_checkout(feature_name, create=True)
            log_info(f"Created new branch: {feature_name}")
    except Exception as error:
        log_error(f"Failed to create/switch to branch {feature_name}: {error}")

    # Copy templates
    copied_files_csv = await copy_templates(feature_dir, templates)

    # Output results
    results = {
        "BRANCH_NAME": feature_name,
        "FEATURE_FOLDER": str(feature_dir),
        "ISSUE_NUMBER": str(feature_id),
        "TITLE": feature_title,
        "REQUIREMENT": requirement,
        "COPIED_TEMPLATES": copied_files_csv.split(",") if copied_files_csv else [],
    }

    output_results(results, output_json)


async def update_existing_feature(
    feature_name: str,
    labels: List[str],
    requirement: str,
    templates: List[str],
    output_json: bool,
    specs_folder: str,
    issue_manager_type: str,
) -> None:
    """Update an existing feature."""
    feature_id = extract_feature_id(feature_name)
    feature_parent_dir = Path.cwd() / specs_folder
    feature_dir = feature_parent_dir / feature_name

    if not feature_dir.exists():
        log_error(f"Feature directory '{feature_dir}' not found")

    # Checkout branch
    try:
        await git_checkout(feature_name, create=False)
    except Exception:
        log_error(f"Failed to switch to branch {feature_name}")

    if not feature_id or feature_id == 0:
        log_error(f"Could not determine issue from branch '{feature_name}'")

    issue_manager = get_issue_manager(issue_manager_type)
    await issue_manager.update_issue(feature_id, feature_name, feature_dir, labels, requirement)

    # Copy templates
    copied_files_csv = await copy_templates(feature_dir, templates)

    # Get feature title
    feature_title = feature_name
    issue_json_path = feature_dir / "issue.json"
    if issue_json_path.exists():
        with open(issue_json_path) as f:
            issue_data = json.load(f)
            feature_title = issue_data.get("title", feature_name)

    # Output results
    results = {
        "BRANCH_NAME": feature_name,
        "FEATURE_FOLDER": str(feature_dir),
        "ISSUE_NUMBER": str(feature_id),
        "TITLE": feature_title,
        "REQUIREMENT": requirement,
        "COPIED_TEMPLATES": copied_files_csv.split(",") if copied_files_csv else [],
    }

    output_results(results, output_json)


async def copy_templates(feature_dir: Path, requested_templates: List[str]) -> str:
    """Copy templates to feature directory."""
    if not requested_templates:
        log_info("ℹ️  No templates specified. Only creating directory structure.")
        return ""

    repo_root = get_repo_root()
    templates_dir = repo_root / ".cwai/templates/outline"
    copied_files = []

    for template in requested_templates:
        template = template.strip()
        if not template:
            continue

        source_path = templates_dir / template
        if not source_path.exists() and not template.endswith(".md"):
            source_path = templates_dir / f"{template}.md"

        if not source_path.exists():
            log_warn(f"Template '{template}' not found in {templates_dir}")
            continue

        feature_dir.mkdir(parents=True, exist_ok=True)
        destination = feature_dir / source_path.name

        if destination.exists():
            log_warn(
                f"Template '{destination.name}' already exists in {feature_dir}; skipping"
            )
            continue

        shutil.copy2(source_path, destination)
        log_info(f"Copied template: {source_path.name}")
        copied_files.append(source_path.name)

    return ",".join(copied_files)


@click.command()
@click.argument("requirement")
@click.option("--json", "output_json", is_flag=True, help="Output data as JSON instead of text")
@click.option("--title", help="Explicit title for the feature")
@click.option(
    "-t",
    "--template",
    "templates",
    multiple=True,
    help="Templates to copy (can be used multiple times)",
)
@click.option("-l", "--labels", help="Labels to add to GitHub issue (comma separated)")
def create_feature_command(
    requirement: str,
    output_json: bool,
    title: Optional[str],
    templates: tuple,
    labels: Optional[str],
) -> None:
    """Create a new feature or update an existing one."""
    parsed_labels = parse_labels(labels)
    template_list = list(templates) if templates else []

    try:
        asyncio.run(
            create_feature_command_async(
                requirement, output_json, title or "", template_list, parsed_labels
            )
        )
    except Exception as error:
        log_error(f"Feature creation failed: {error}")


def main():
    """Entry point for cwai-create-feature command."""
    try:
        create_feature_command()
    except KeyboardInterrupt:
        from rich.console import Console

        console = Console()
        console.print("\n\nOperation cancelled by user", style="yellow")
        sys.exit(1)


if __name__ == "__main__":
    main()
