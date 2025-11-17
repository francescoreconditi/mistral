"""Tests for authentication module.

DEPRECATED: These tests are deprecated since migration to OpenAI.
OpenAI uses OPENAI_API_KEY environment variable for authentication.
"""

import warnings
from unittest.mock import patch

import pytest

from mistral.utils.auth import authenticate_huggingface


class TestAuthentication:
    """Test suite for deprecated HuggingFace authentication."""

    def test_authenticate_shows_deprecation_warning(self):
        """Test that authenticate_huggingface shows deprecation warning."""
        with warnings.catch_warnings(record=True) as w:
            warnings.simplefilter("always")
            authenticate_huggingface(token="test_token")

            assert len(w) == 1
            assert issubclass(w[0].category, DeprecationWarning)
            assert "deprecated" in str(w[0].message).lower()
            assert "openai" in str(w[0].message).lower()

    def test_authenticate_does_not_raise_without_token(self):
        """Test that authenticate_huggingface doesn't raise error (deprecated)."""
        with warnings.catch_warnings(record=True):
            warnings.simplefilter("always")
            # Should not raise even without token since it's deprecated
            authenticate_huggingface()

    def test_authenticate_with_parameter_token(self):
        """Test that function accepts token parameter (backward compatibility)."""
        with warnings.catch_warnings(record=True):
            warnings.simplefilter("always")
            # Should not raise
            authenticate_huggingface(token="param_token")
