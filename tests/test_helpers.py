"""Tests for helpers_py module."""

import pytest
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from utils.helpers_py import (
    requirement_to_title,
    title_to_slug,
    padd_feature_id,
    extract_feature_id,
    detect_feature_name,
    concatenate_arrays,
    parse_labels,
)


def test_requirement_to_title():
    """Test converting requirement to title."""
    requirement = "Create a new feature for user authentication"
    expected = "Create a new feature for"
    assert requirement_to_title(requirement) == expected


def test_requirement_to_title_with_special_chars():
    """Test title extraction with special characters."""
    requirement = "Add @user #login feature!"
    expected = "Add user login feature"
    assert requirement_to_title(requirement) == expected


def test_title_to_slug():
    """Test converting title to slug."""
    title = "Create New Feature"
    expected = "create-new-feature"
    assert title_to_slug(title) == expected


def test_title_to_slug_with_special_chars():
    """Test slug creation with special characters."""
    title = "My Feature @ Test!"
    expected = "my-feature-test"
    assert title_to_slug(title) == expected


def test_padd_feature_id():
    """Test padding feature ID."""
    assert padd_feature_id(1) == "00001"
    assert padd_feature_id(42) == "00042"
    assert padd_feature_id(12345) == "12345"


def test_extract_feature_id():
    """Test extracting feature ID from name."""
    assert extract_feature_id("00001-my-feature") == 1
    assert extract_feature_id("00042-test-feature") == 42
    assert extract_feature_id("invalid") == 0


def test_detect_feature_name():
    """Test detecting feature name in requirement."""
    requirement = "Update 00001-my-feature with new changes"
    assert detect_feature_name(requirement) == "00001-my-feature"
    
    requirement_no_feature = "Create a new feature"
    assert detect_feature_name(requirement_no_feature) is None


def test_concatenate_arrays():
    """Test concatenating arrays with override logic."""
    # Simple concatenation
    result = concatenate_arrays("a,b", "c,d")
    assert result == "a,b,c,d"
    
    # Remove with minus prefix
    result = concatenate_arrays("a,b,c", "-b,d")
    assert result == "a,c,d"
    
    # Deduplicate
    result = concatenate_arrays("a,b", "b,c")
    assert result == "a,b,c"


def test_parse_labels():
    """Test parsing labels string."""
    assert parse_labels("bug,feature,enhancement") == ["bug", "feature", "enhancement"]
    assert parse_labels("bug, feature , enhancement ") == ["bug", "feature", "enhancement"]
    assert parse_labels("") == []
    assert parse_labels(None) == []
