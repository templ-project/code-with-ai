"""Utility functions for CwAI CLI tools."""

import os
import re
import subprocess
from pathlib import Path
from typing import List, Optional


def requirement_to_title(requirement: str) -> str:
    """Convert a requirement string to a title by extracting first 5 words."""
    return " ".join(
        re.sub(r"[^A-Za-z0-9_-]", " ", requirement.replace("\n", " "))
        .strip()
        .split()[:5]
    )


def title_to_slug(title: str) -> str:
    """Convert a title to a URL-friendly slug."""
    return re.sub(r"^-+|-+$", "", re.sub(r"[^a-z0-9]+", "-", title.lower()))


def padd_feature_id(feature_id: int) -> str:
    """Pad feature ID to 5 digits with leading zeros."""
    return str(feature_id).zfill(5)


def extract_feature_id(feature_name: str) -> int:
    """Extract feature ID from a feature name like '00001-my-feature'."""
    match = re.match(r"^(\d{5})", feature_name)
    if not match:
        return 0
    return int(match.group(1))


def detect_feature_name(requirement: str) -> Optional[str]:
    """Detect existing feature name in requirement string."""
    match = re.search(r"\d{5}-[a-z0-9][a-z0-9-]*", requirement)
    if not match:
        return None
    return match.group(0)


def join_by_comma(arr: List[str]) -> str:
    """Join list of strings by comma."""
    return ",".join(arr)


def concatenate_arrays(array1_string: str, array2_string: str) -> str:
    """
    Concatenate two comma-separated strings, with array2 overriding array1.
    Items in array2 starting with '-' remove that item from the result.
    """
    remove_set = set()
    seen_set = set()
    out_list = []

    array1 = array1_string.split(",") if array1_string else []
    array2 = array2_string.split(",") if array2_string else []

    # Build remove set from array2 (items starting with -)
    for item in array2:
        if item.startswith("-") and len(item) > 1:
            remove_set.add(item[1:])

    # Add items from array1 that aren't in remove set
    for item in array1:
        if not item or item in remove_set or item in seen_set:
            continue
        seen_set.add(item)
        out_list.append(item)

    # Add new items from array2
    for item in array2:
        if not item or item.startswith("-") or item in seen_set:
            continue
        seen_set.add(item)
        out_list.append(item)

    return ",".join(out_list)


def get_absolute_path(input_path: str) -> Path:
    """Get absolute path, expanding tilde and resolving relative paths."""
    path = Path(input_path).expanduser()
    if not path.is_absolute():
        path = Path.cwd() / path
    return path.resolve()


def get_repo_root() -> Path:
    """
    Get the repository root directory.
    First tries using git to find the repository root, then falls back to current directory.
    """
    try:
        # Use git to find the repository root (the folder containing .git)
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=True,
        )
        return Path(result.stdout.strip())
    except (subprocess.CalledProcessError, FileNotFoundError):
        # If git command fails (not in a git repo or git not installed), use current working directory
        return Path.cwd()


async def git_branch_exists(branch_name: str) -> bool:
    """Check if a git branch exists locally or remotely."""
    try:
        subprocess.run(
            ["git", "rev-parse", "--verify", "--quiet", f"refs/heads/{branch_name}"],
            capture_output=True,
            check=True,
        )
        return True
    except subprocess.CalledProcessError:
        try:
            subprocess.run(
                ["git", "rev-parse", "--verify", "--quiet", f"refs/remotes/origin/{branch_name}"],
                capture_output=True,
                check=True,
            )
            return True
        except subprocess.CalledProcessError:
            return False


async def git_checkout(branch_name: str, create: bool = False) -> None:
    """Checkout or create a git branch."""
    cmd = ["git", "checkout"]
    if create:
        cmd.append("-b")
    cmd.append(branch_name)
    
    subprocess.run(cmd, check=True, capture_output=True)


def load_environment(repo_root: Path) -> None:
    """Load environment variables from .env and .env.local files."""
    from dotenv import load_dotenv

    env_file = repo_root / ".env"
    env_local_file = repo_root / ".env.local"

    if env_file.exists():
        load_dotenv(env_file)
    
    if env_local_file.exists():
        load_dotenv(env_local_file, override=True)


def output_results(results: dict, as_json: bool = False) -> None:
    """Output results as JSON or formatted text."""
    import json
    from utils.logger_py import log_info

    if as_json:
        # Output JSON to stdout (for programmatic consumption)
        print(json.dumps(results, indent=2))
    else:
        # Output formatted text to stderr (via logger)
        log_info("Results:")
        for key, value in results.items():
            if isinstance(value, list):
                log_info(f"  {key}: {', '.join(value)}")
            else:
                log_info(f"  {key}: {value}")


def parse_labels(labels_str: Optional[str]) -> List[str]:
    """Parse comma-separated labels string into list."""
    if not labels_str:
        return []
    return [label.strip() for label in labels_str.split(",") if label.strip()]
