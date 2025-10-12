"""Logging utilities for CwAI CLI tools."""

import sys
from rich.console import Console

# Create console that writes to stderr (not stdout)
# This ensures logs don't interfere with JSON output on stdout
console = Console(stderr=True)


def log_info(message: str) -> None:
    """Log an info message to stderr."""
    console.print(f"[cyan]ℹ️  {message}[/cyan]")


def log_success(message: str) -> None:
    """Log a success message to stderr."""
    console.print(f"[green]✅ {message}[/green]")


def log_warn(message: str) -> None:
    """Log a warning message to stderr."""
    console.print(f"[yellow]⚠️  {message}[/yellow]")


def log_error(message: str, exit_code: int = 1) -> None:
    """Log an error message to stderr and exit."""
    console.print(f"[red]❌ {message}[/red]")
    sys.exit(exit_code)


def log_debug(message: str) -> None:
    """Log a debug message to stderr."""
    console.print(f"[dim]🔍 {message}[/dim]")
