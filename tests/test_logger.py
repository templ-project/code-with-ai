"""Tests for logger_py module."""

from io import StringIO
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from utils.logger_py import log_info, log_success, log_warn


def test_log_info(capsys):
    """Test info logging."""
    log_info("Test info message")
    captured = capsys.readouterr()
    assert "Test info message" in captured.err


def test_log_success(capsys):
    """Test success logging."""
    log_success("Test success message")
    captured = capsys.readouterr()
    assert "Test success message" in captured.err


def test_log_warn(capsys):
    """Test warning logging."""
    log_warn("Test warning message")
    captured = capsys.readouterr()
    assert "Test warning message" in captured.err
