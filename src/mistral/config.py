"""Configuration settings for Mistral SQL Assistant."""

import os
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv

load_dotenv()


class Config:
    """Central configuration for the application."""

    # HuggingFace Configuration
    HUGGINGFACE_TOKEN: Optional[str] = os.getenv("HUGGINGFACE_TOKEN")

    # Device Configuration
    DEVICE: str = os.getenv("DEVICE", "cuda")

    # Model Configuration
    OLLAMA_MODEL: str = os.getenv("OLLAMA_MODEL", "mistral")
    OLLAMA_HOST: str = os.getenv("OLLAMA_HOST", "localhost:11434")
    EMBEDDING_MODEL: str = os.getenv(
        "EMBEDDING_MODEL", "sentence-transformers/all-MiniLM-L6-v2"
    )

    # Vector Store Configuration
    VECTOR_STORE_DIR: Path = Path(os.getenv("VECTOR_STORE_DIR", "./data/db_index"))

    # Data Paths
    PROJECT_ROOT: Path = Path(__file__).parent.parent.parent
    DATA_DIR: Path = PROJECT_ROOT / "data"
    SCHEMA_FILE: Path = DATA_DIR / "schema.sql"

    # Streamlit Configuration
    STREAMLIT_SERVER_PORT: int = int(os.getenv("STREAMLIT_SERVER_PORT", "8501"))
    STREAMLIT_SERVER_ADDRESS: str = os.getenv("STREAMLIT_SERVER_ADDRESS", "localhost")

    @classmethod
    def validate(cls) -> None:
        """Validate configuration settings."""
        if not cls.HUGGINGFACE_TOKEN:
            raise ValueError("HUGGINGFACE_TOKEN environment variable is required")

        if not cls.SCHEMA_FILE.exists():
            raise FileNotFoundError(f"Schema file not found: {cls.SCHEMA_FILE}")

        # Create directories if they don't exist
        cls.VECTOR_STORE_DIR.mkdir(parents=True, exist_ok=True)
        cls.DATA_DIR.mkdir(parents=True, exist_ok=True)


# Global config instance
config = Config()
