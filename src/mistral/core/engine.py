"""Query engine implementation for Mistral SQL Assistant."""

import logging
from typing import Optional

from langchain_community.llms import Ollama
from llama_index import ServiceContext, StorageContext, load_index_from_storage
from llama_index.embeddings import HuggingFaceEmbedding
from llama_index.llms.langchain import LangChainLLM

from mistral.config import config
from mistral.utils.auth import authenticate_huggingface

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

    # Authenticate with HuggingFace
    authenticate_huggingface()

    # Validate configuration
    config.validate()

    # Initialize LLM
    logger.info(
        f"Initializing LLM with model: {config.OLLAMA_MODEL} at {config.OLLAMA_HOST}"
    )
    llm = LangChainLLM(
        llm=Ollama(model=config.OLLAMA_MODEL, base_url=f"http://{config.OLLAMA_HOST}")
    )

    # Initialize embedding model
    logger.info(
        f"Initializing embedding model: {config.EMBEDDING_MODEL} on device: {config.DEVICE}"
    )
    embed_model = HuggingFaceEmbedding(
        model_name=config.EMBEDDING_MODEL,
        device=config.DEVICE,
    )

    # Create service context
    service_context = ServiceContext.from_defaults(llm=llm, embed_model=embed_model)

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
    index = load_index_from_storage(
        storage_context=storage_context, service_context=service_context
    )

    logger.info("Query engine loaded successfully")
    return index.as_query_engine()
