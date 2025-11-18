"""Query engine implementation for Mistral SQL Assistant."""

import logging

from llama_index.core import Settings, StorageContext, load_index_from_storage
from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.llms.openai import OpenAI

from mistral.config import config

logger = logging.getLogger(__name__)


def load_query_engine() -> object:
    """Load and configure the query engine.

    Returns:
        Query engine instance

    Raises:
        FileNotFoundError: If vector store directory doesn't exist
        ValueError: If authentication fails
    """
    logger.info("Loading query engine...")

    # Validate configuration
    config.validate()

    # Initialize OpenAI LLM
    logger.info(f"Initializing OpenAI LLM with model: {config.OPENAI_MODEL}")
    llm = OpenAI(
        model=config.OPENAI_MODEL,
        api_key=config.OPENAI_API_KEY,
        temperature=config.OPENAI_TEMPERATURE,
    )

    # Initialize OpenAI embedding model
    logger.info(
        f"Initializing OpenAI embedding model: {config.OPENAI_EMBEDDING_MODEL}"
    )
    embed_model = OpenAIEmbedding(
        model=config.OPENAI_EMBEDDING_MODEL,
        api_key=config.OPENAI_API_KEY,
    )

    # Configure global settings
    Settings.llm = llm
    Settings.embed_model = embed_model

    # Load vector store
    if not config.VECTOR_STORE_DIR.exists():
        raise FileNotFoundError(
            f"Vector store directory not found: {config.VECTOR_STORE_DIR}. "
            "Please run the index creation script first."
        )

    logger.info(f"Loading vector store from: {config.VECTOR_STORE_DIR}")
    storage_context = StorageContext.from_defaults(
        persist_dir=str(config.VECTOR_STORE_DIR)
    )
    index = load_index_from_storage(storage_context=storage_context)

    logger.info("Query engine loaded successfully")
    # Use similarity_top_k=20 to ensure instruction sections are retrieved
    # (empirical testing showed key instructions at positions 10-17)
    return index.as_query_engine(similarity_top_k=20)
