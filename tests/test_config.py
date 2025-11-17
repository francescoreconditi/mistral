"""Tests for configuration module."""

from pathlib import Path
from unittest.mock import patch

import pytest

from mistral.config import Config


class TestConfig:
    """Test configuration functionality."""

    def test_config_default_values(self):
        """Test default configuration values."""
        config = Config()

        assert config.OPENAI_MODEL == "gpt-4o-mini"
        assert config.OPENAI_EMBEDDING_MODEL == "text-embedding-3-small"
        assert config.OPENAI_TEMPERATURE == 0.0
        assert isinstance(config.VECTOR_STORE_DIR, Path)

    def test_validation_missing_token(self):
        """Test validation fails with missing OpenAI API key."""
        with patch.object(Config, "OPENAI_API_KEY", None):
            with pytest.raises(ValueError, match="OPENAI_API_KEY"):
                Config.validate()

    @patch("pathlib.Path.exists")
    def test_validation_missing_schema(self, mock_exists):
        """Test validation fails with missing schema file."""
        mock_exists.return_value = False
        with patch.object(Config, "OPENAI_API_KEY", "test_token"):
            with pytest.raises(FileNotFoundError):
                Config.validate()

    def test_validate_creates_directories(self, tmp_path):
        """Test that validate creates necessary directories."""
        with patch.object(Config, "OPENAI_API_KEY", "test_token"):
            with patch.object(Config, "VECTOR_STORE_DIR", tmp_path / "db_index"):
                with patch.object(Config, "DATA_DIR", tmp_path / "data"):
                    with patch.object(
                        Config, "SCHEMA_FILE", tmp_path / "data" / "schema.sql"
                    ):
                        # Create schema file
                        (tmp_path / "data").mkdir(parents=True)
                        (tmp_path / "data" / "schema.sql").touch()

                        Config.validate()

                        assert (tmp_path / "db_index").exists()
                        assert (tmp_path / "data").exists()

    def test_validate_raises_error_if_schema_missing(self, tmp_path):
        """Test that validate raises error if schema file doesn't exist."""
        with patch.object(Config, "OPENAI_API_KEY", "test_token"):
            with patch.object(
                Config, "SCHEMA_FILE", tmp_path / "nonexistent" / "schema.sql"
            ):
                with pytest.raises(FileNotFoundError, match="Schema file not found"):
                    Config.validate()
