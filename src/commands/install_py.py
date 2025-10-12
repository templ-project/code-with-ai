#!/usr/bin/env python3
"""Install command for CwAI CLI."""

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import questionary
from rich.console import Console

import sys
from pathlib import Path
# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from utils.helpers_py import get_absolute_path
from utils.logger_py import log_error, log_info, log_success, log_warn

LOGO = """
   _____                _____
  / ____|           _  |_   _|
 | |     __      _ / \\   | |
 | |     \\ \\ /\\ / / / \\  | |
 | |____  \\ V  V / ____\\_| |_
  \\_____|  \\_/\\_/_/    \\_____/

            C w A I
          Code with AI
"""

REPO_URL = "https://github.com/templ-project/code-with-ai.git"


def install_command():
    """Main installation command."""
    console = Console()
    console.print(LOGO, style="blue")

    log_info(f"Python version: {sys.version.split()[0]}")

    # Clone repo to temp directory
    temp_dir = Path(tempfile.mkdtemp(prefix="cwai-install-"))
    cwai_source_dir = None

    try:
        log_info("Cloning code-with-ai repository...")
        subprocess.run(
            ["git", "clone", "--depth", "1", REPO_URL, str(temp_dir)],
            check=True,
            capture_output=True,
        )
        log_info(f"Repository cloned to {temp_dir}")

        cwai_source_dir = temp_dir / ".cwai"

        if not cwai_source_dir.exists():
            log_error(f"Source .cwai directory not found in cloned repo: {cwai_source_dir}")

    except subprocess.CalledProcessError as error:
        log_error(f"Failed to clone repository: {error}")

    # Select AI Client
    selected_ai_client = questionary.select(
        "What AI Client do you want to install CwAI for?",
        choices=[
            questionary.Choice("VSCode Copilot", value="vscode"),
            questionary.Choice("Claude", value="claude"),
            questionary.Choice("Gemini", value="gemini"),
        ],
    ).ask()

    if not selected_ai_client:
        log_error("AI client selection is required")

    log_info(f"Selected AI Client: {get_client_display_name(selected_ai_client)}")

    # Select install type
    install_type = questionary.select(
        "How do you want to install CwAI?",
        choices=[
            questionary.Choice("Locally (in project)", value="local"),
            questionary.Choice("Globally", value="global"),
        ],
    ).ask()

    if not install_type:
        log_error("Install type selection is required")

    # Get target path
    if install_type == "local":
        project_path = questionary.path(
            "Please provide the path to the project:",
            only_directories=True,
        ).ask()

        if not project_path:
            log_error("Path cannot be empty")

        target_path = get_absolute_path(project_path)

        if not target_path.exists():
            log_error("Path does not exist")
        if not target_path.is_dir():
            log_error("Path is not a directory")
    else:
        target_path = get_global_install_path(selected_ai_client)

    log_info(f"Target path: {target_path}")

    # Check existing installation
    check_existing_installation(target_path, selected_ai_client)

    # Install prompts
    install_prompts(cwai_source_dir, target_path, selected_ai_client)

    # Install .cwai folder
    install_cwai_folder(cwai_source_dir, target_path)

    # Cleanup temporary directory
    try:
        log_info("Cleaning up temporary files...")
        shutil.rmtree(temp_dir)
        log_info("Temporary files removed")
    except Exception as error:
        log_warn(f"Failed to remove temporary directory: {error}")

    # Success message
    console.print()
    log_success("CwAI installation completed successfully!")
    console.print("\nInstallation Summary:")
    console.print(f"  AI Client: {get_client_display_name(selected_ai_client)}")
    console.print(f"  Install Type: {install_type}")
    console.print(f"  Target Path: {target_path}")
    console.print(f"  CwAI Assets: {target_path / '.cwai'}")

    # Show client-specific paths
    if selected_ai_client == "vscode":
        console.print(f"  Prompts: {target_path / '.github/prompts/*.prompt.md'}")
    elif selected_ai_client == "claude":
        console.print(f"  Prompts: {target_path / 'prompts/*.md'}")
    elif selected_ai_client == "gemini":
        console.print(f"  Templates: {target_path / 'templates/*.md'}")

    console.print(
        f"\nYou can now start using CwAI with your {get_client_display_name(selected_ai_client)}!"
    )


def get_client_display_name(client: str) -> str:
    """Get display name for AI client."""
    display_names = {
        "vscode": "VSCode Copilot",
        "claude": "Claude",
        "gemini": "Gemini",
    }
    return display_names.get(client, client)


def get_global_install_path(client: str) -> Path:
    """Get global installation path for AI client."""
    home = Path.home()

    if client == "vscode":
        if sys.platform == "darwin":
            return home / "Library/Application Support/Code/User/globalStorage/github.copilot"
        return home / ".vscode/extensions/github.copilot"
    elif client == "claude":
        return home / ".config/claude"
    elif client == "gemini":
        return home / ".config/gemini"

    log_error(f"Unknown AI client: {client}")


def check_existing_installation(target_path: Path, selected_ai_client: str) -> None:
    """Check for existing CwAI installation and prompt user for action."""
    existing_paths = []

    # Check for client-specific paths
    if selected_ai_client == "vscode":
        github_prompts_path = target_path / ".github/prompts"
        if github_prompts_path.exists():
            existing_paths.append(github_prompts_path)
    elif selected_ai_client == "claude":
        prompts_path = target_path / "prompts"
        if prompts_path.exists():
            existing_paths.append(prompts_path)
    elif selected_ai_client == "gemini":
        templates_path = target_path / "templates"
        if templates_path.exists():
            existing_paths.append(templates_path)

    # Check for .cwai folder
    cwai_path = target_path / ".cwai"
    if cwai_path.exists():
        existing_paths.append(cwai_path)

    if existing_paths:
        console = Console()
        console.print("\nExisting CwAI installation detected at:")
        for p in existing_paths:
            console.print(f"  - {p}")

        action = questionary.select(
            "How should we proceed?",
            choices=[
                questionary.Choice("Copy Over Existing", value="overwrite"),
                questionary.Choice("Remove folders and copy again", value="remove"),
            ],
        ).ask()

        if not action:
            log_error("Installation cancelled")

        if action == "remove":
            log_info("Removing existing installation...")
            for p in existing_paths:
                shutil.rmtree(p, ignore_errors=True)
                log_info(f"Removed: {p}")
        else:
            log_info("Will copy over existing installation")


def install_prompts(cwai_source_dir: Path, target_path: Path, selected_ai_client: str) -> None:
    """Install AI client-specific prompts."""
    src_prompts_dir = cwai_source_dir / "prompts"

    if not src_prompts_dir.exists():
        log_error(f"Source prompts directory not found: {src_prompts_dir}")

    if selected_ai_client == "vscode":
        install_vscode_prompts(src_prompts_dir, target_path)
    elif selected_ai_client == "claude":
        install_claude_prompts(src_prompts_dir, target_path)
    elif selected_ai_client == "gemini":
        install_gemini_prompts(src_prompts_dir, target_path)

    log_success(f"Prompts installed successfully for {get_client_display_name(selected_ai_client)}")


def install_vscode_prompts(src_prompts_dir: Path, target_path: Path) -> None:
    """Install VSCode Copilot prompts."""
    dest_dir = target_path / ".github/prompts"
    log_info(f"Installing VSCode Copilot prompts to {dest_dir}")

    dest_dir.mkdir(parents=True, exist_ok=True)

    for file in src_prompts_dir.glob("*.md"):
        base_name = file.stem
        dest_file = dest_dir / f"{base_name}.prompt.md"
        shutil.copy2(file, dest_file)
        log_info(f"Installed: {base_name}.prompt.md")


def install_claude_prompts(src_prompts_dir: Path, target_path: Path) -> None:
    """Install Claude prompts."""
    dest_dir = target_path / "prompts"
    log_info(f"Installing Claude prompts to {dest_dir}")

    dest_dir.mkdir(parents=True, exist_ok=True)

    for file in src_prompts_dir.glob("*.md"):
        dest_file = dest_dir / file.name
        shutil.copy2(file, dest_file)
        log_info(f"Installed: {file.name}")


def install_gemini_prompts(src_prompts_dir: Path, target_path: Path) -> None:
    """Install Gemini prompts."""
    dest_dir = target_path / "templates"
    log_info(f"Installing Gemini prompts to {dest_dir}")

    dest_dir.mkdir(parents=True, exist_ok=True)

    for file in src_prompts_dir.glob("*.md"):
        dest_file = dest_dir / file.name
        shutil.copy2(file, dest_file)
        log_info(f"Installed: {file.name}")


def install_cwai_folder(cwai_source_dir: Path, target_path: Path) -> None:
    """Install .cwai folder."""
    dest_cwai = target_path / ".cwai"

    log_info(f"Installing .cwai folder from {cwai_source_dir} to {dest_cwai}")

    target_path.mkdir(parents=True, exist_ok=True)
    if dest_cwai.exists():
        shutil.rmtree(dest_cwai)
    shutil.copytree(cwai_source_dir, dest_cwai)

    log_success(".cwai folder installed successfully")


def main():
    """Entry point for cwai-install command."""
    try:
        install_command()
    except KeyboardInterrupt:
        console = Console()
        console.print("\n\nInstallation cancelled by user", style="yellow")
        sys.exit(1)
    except Exception as error:
        log_error(f"Installation failed: {error}")


if __name__ == "__main__":
    main()
