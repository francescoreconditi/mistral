"""Tests for configuration module."""

import os
from pathlib import Path
from unittest.mock import patch

import pytest

from mistral.config import Config


class TestConfig:
    """Test configuration functionality."""

    def test_config_default_values(self):
        """Test default configuration values."""
        config = Config()

        assert config.DEVICE == "cuda"  # Default from env or "cuda"
        assert config.OLLAMA_MODEL == "mistral"
        assert config.EMBEDDING_MODEL == "sentence-transformers/all-MiniLM-L6-v2"
        assert isinstance(config.VECTOR_STORE_DIR, Path)

    @patch.dict(os.environ, {"DEVICE": "cpu", "OLLAMA_MODEL": "llama"})
    def test_config_from_environment(self):
        """Test configuration loading from environment variables."""
        config = Config()

        assert config.DEVICE == "cpu"
        assert config.OLLAMA_MODEL == "llama"

    def test_validation_missing_token(self):
        """Test validation fails with missing HuggingFace token."""
        config = Config()
        config.HUGGINGFACE_TOKEN = None

        with pytest.raises(ValueError, match="HUGGINGFACE_TOKEN"):
            config.validate()

    @patch("pathlib.Path.exists")
    def test_validation_missing_schema(self, mock_exists):
        """Test validation fails with missing schema file."""
        mock_exists.return_value = False
        config = Config()
        config.HUGGINGFACE_TOKEN = "test_token"

        with pytest.raises(FileNotFoundError):
            config.validate()
