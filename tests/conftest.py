"""Pytest configuration and fixtures."""

from pathlib import Path
from unittest.mock import MagicMock

import pytest


@pytest.fixture
def mock_config():
    """Mock configuration for tests."""
    config = MagicMock()
    config.HUGGINGFACE_TOKEN = "test_token"
    config.DEVICE = "cpu"
    config.OLLAMA_MODEL = "mistral"
    config.EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2"
    config.VECTOR_STORE_DIR = Path("./test_db_index")
    config.SCHEMA_FILE = Path("./test_schema.sql")
    return config


@pytest.fixture
def sample_query():
    """Sample query for testing."""
    return "SELECT * FROM users WHERE age > 25"


@pytest.fixture
def sample_response():
    """Sample response for testing."""
    return "Here is your SQL query: SELECT * FROM users WHERE age > 25"
