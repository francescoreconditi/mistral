"""Configuration settings for Mistral SQL Assistant."""

import os
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv

load_dotenv()


class Config:
    """Central configuration for the application."""

    # OpenAI Configuration
    OPENAI_API_KEY: Optional[str] = os.getenv("OPENAI_API_KEY")
    OPENAI_MODEL: str = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
    OPENAI_EMBEDDING_MODEL: str = os.getenv(
        "OPENAI_EMBEDDING_MODEL", "text-embedding-3-small"
    )
    OPENAI_TEMPERATURE: float = float(os.getenv("OPENAI_TEMPERATURE", "0.0"))

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
        if not cls.OPENAI_API_KEY:
            raise ValueError(
                "OPENAI_API_KEY environment variable is required. "
                "Get your API key at https://platform.openai.com/api-keys"
            )

        if not cls.SCHEMA_FILE.exists():
            raise FileNotFoundError(f"Schema file not found: {cls.SCHEMA_FILE}")

        # Create directories if they don't exist
        cls.VECTOR_STORE_DIR.mkdir(parents=True, exist_ok=True)
        cls.DATA_DIR.mkdir(parents=True, exist_ok=True)


# Global config instance
config = Config()
