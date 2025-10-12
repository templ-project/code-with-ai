"""Issue manager implementations for CwAI CLI tools."""

import asyncio
import json
import os
import random
import subprocess
from datetime import datetime
from pathlib import Path
from typing import List, Optional

from utils.helpers_py import concatenate_arrays, padd_feature_id
from utils.logger_py import log_info


def generate_hex_color() -> str:
    """Generate a random hex color."""
    random_int = random.randint(0, 16777216)
    return f"{random_int:06X}"


async def get_git_user_name() -> str:
    """Get git user name from git config."""
    try:
        result = subprocess.run(
            ["git", "config", "--get", "user.name"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "Unknown User"


async def get_git_user_email() -> str:
    """Get git user email from git config."""
    try:
        result = subprocess.run(
            ["git", "config", "--get", "user.email"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "unknown@example.com"


class LocalFSIssueManager:
    """LocalFS-based issue manager."""

    async def create_issue(
        self,
        feature_slug: str,
        feature_title: str,
        feature_parent_dir: Path,
        feature_labels: List[str],
        feature_body: str,
    ) -> int:
        """Create a new local issue."""
        if os.environ.get("LOCALFS_FEATURE_ID"):
            feature_id = int(os.environ["LOCALFS_FEATURE_ID"])
        else:
            specs_folder = os.environ.get("CWAI_SPECS_FOLDER", "specs")
            existing_count = 0

            if Path(specs_folder).exists():
                # Count only directories (not files) asynchronously
                entries = list(Path(specs_folder).iterdir())
                is_dir_checks = [entry.is_dir() for entry in entries]
                existing_count = sum(is_dir_checks)

            feature_id = existing_count + 1

        feature_padded_id = padd_feature_id(feature_id)
        feature_dir = feature_parent_dir / f"{feature_padded_id}-{feature_slug}"
        feature_dir.mkdir(parents=True, exist_ok=True)

        now = datetime.utcnow().isoformat() + "Z"
        user_name = await get_git_user_name()
        user_email = await get_git_user_email()
        author = f"{user_name} <{user_email}>"

        issue_data = {
            "author": author,
            "id": feature_id,
            "title": feature_title,
            "description": feature_body,
            "labels": feature_labels,
            "created_at": now,
            "updated_at": now,
            "comments": [],
        }

        issue_json_path = feature_dir / "issue.json"
        with open(issue_json_path, "w") as f:
            json.dump(issue_data, f, indent=2)

        log_info(f"✅ Created Local issue (#{feature_id}) {feature_title}")

        return feature_id

    async def update_issue(
        self,
        feature_id: int,
        feature_name: str,
        feature_dir: Path,
        feature_labels: List[str],
        feature_comment: str,
    ) -> None:
        """Update an existing local issue."""
        issue_json_path = feature_dir / "issue.json"

        with open(issue_json_path, "r") as f:
            issue_data = json.load(f)

        now = datetime.utcnow().isoformat() + "Z"
        user_name = await get_git_user_name()
        user_email = await get_git_user_email()
        author = f"{user_name} <{user_email}>"

        sanitized_comment = feature_comment.replace(feature_name, "").strip()

        comment_entry = {
            "author": author,
            "comment": sanitized_comment,
            "created_at": now,
        }

        issue_data["comments"].append(comment_entry)

        # Update labels
        existing_labels = ",".join(issue_data.get("labels", []))
        labels_string = ",".join(feature_labels)
        updated_labels = concatenate_arrays(existing_labels, labels_string)
        issue_data["labels"] = [l for l in updated_labels.split(",") if l]
        issue_data["updated_at"] = now

        with open(issue_json_path, "w") as f:
            json.dump(issue_data, f, indent=2)

        log_info(f"💬 Updated Local issue (#{feature_id}) {feature_name}")


class GitHubIssueManager:
    """GitHub-based issue manager using gh CLI."""

    def __init__(self):
        self.localfs_manager = LocalFSIssueManager()

    async def create_label(
        self, label_name: str, label_color: str = "", label_description: str = ""
    ) -> None:
        """Create a GitHub label if it doesn't exist."""
        color = label_color or generate_hex_color()

        try:
            result = subprocess.run(
                ["gh", "label", "list", "--json", "name", "--jq", ".[].name"],
                capture_output=True,
                text=True,
                check=True,
            )
            existing_labels = [l for l in result.stdout.split("\n") if l]

            if label_name in existing_labels:
                return

            log_info(f"🏷️  Creating label: {label_name}")
            args = ["gh", "label", "create", label_name, "--color", color]
            if label_description:
                args.extend(["--description", label_description])
            subprocess.run(args, check=True, capture_output=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            # Silently ignore if gh CLI is not available or label already exists
            pass

    async def create_issue(
        self,
        feature_slug: str,
        feature_title: str,
        feature_parent_dir: Path,
        feature_labels: List[str],
        feature_body: str,
    ) -> int:
        """Create a new GitHub issue."""
        # Ensure required labels exist
        await self.create_label("task", "0e8a16", "Task item")
        await self.create_label("auto-generated", "bfd4f2", "Automatically generated by script")

        gh_label_args = ["--label", "task", "--label", "auto-generated"]

        # Create any additional labels
        for label in feature_labels:
            if label:
                await self.create_label(label)
                gh_label_args.extend(["--label", label])

        result = subprocess.run(
            [
                "gh",
                "issue",
                "create",
                "--title",
                feature_title,
                "--body",
                feature_body,
                *gh_label_args,
            ],
            capture_output=True,
            text=True,
            check=True,
        )

        issue_url = result.stdout.strip()
        log_info(f"🏷️  Created Github issue: {issue_url}")

        feature_id = int(issue_url.split("/")[-1])
        os.environ["LOCALFS_FEATURE_ID"] = str(feature_id)

        await self.localfs_manager.create_issue(
            feature_slug, feature_title, feature_parent_dir, feature_labels, feature_body
        )

        del os.environ["LOCALFS_FEATURE_ID"]
        return feature_id

    async def update_issue(
        self,
        feature_id: int,
        feature_name: str,
        feature_dir: Path,
        feature_labels: List[str],
        feature_comment: str,
    ) -> None:
        """Update an existing GitHub issue."""
        add_labels = []
        remove_labels = []

        for label in feature_labels:
            if label.startswith("-"):
                remove_labels.append(label[1:])
            else:
                add_labels.append(label)
                await self.create_label(label)

        if add_labels:
            subprocess.run(
                [
                    "gh",
                    "issue",
                    "edit",
                    str(feature_id),
                    "--add-label",
                    ",".join(add_labels),
                ],
                check=True,
                capture_output=True,
            )
            log_info(f"🏷️  Added labels to issue #{feature_id}: {', '.join(add_labels)}")

        if remove_labels:
            subprocess.run(
                [
                    "gh",
                    "issue",
                    "edit",
                    str(feature_id),
                    "--remove-label",
                    ",".join(remove_labels),
                ],
                check=True,
                capture_output=True,
            )
            log_info(f"🏷️  Removed labels from issue #{feature_id}: {', '.join(remove_labels)}")

        subprocess.run(
            ["gh", "issue", "comment", str(feature_id), "--body", feature_comment],
            check=True,
            capture_output=True,
        )
        log_info(f"💬 Added comment to Github issue #{feature_id}")

        await self.localfs_manager.update_issue(
            feature_id, feature_name, feature_dir, feature_labels, feature_comment
        )


def get_issue_manager(manager_type: str):
    """Factory function to get the appropriate issue manager."""
    if manager_type == "github":
        return GitHubIssueManager()
    return LocalFSIssueManager()
