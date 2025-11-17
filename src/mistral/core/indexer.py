"""Vector index creation for Mistral SQL Assistant."""

import logging

from llama_index.core import SimpleDirectoryReader, VectorStoreIndex, Settings
from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.llms.openai import OpenAI

from mistral.config import config

logger = logging.getLogger(__name__)


def create_index() -> None:
    """Create vector index from SQL schema file.

    Raises:
        FileNotFoundError: If schema file doesn't exist
        ValueError: If authentication fails
    """
    logger.info("Starting index creation...")

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

    # Load schema document
    logger.info(f"Loading schema from: {config.SCHEMA_FILE}")
    documents = SimpleDirectoryReader(input_files=[str(config.SCHEMA_FILE)]).load_data()

    # Create index
    logger.info("Creating vector index...")
    index = VectorStoreIndex.from_documents(documents)

    # Persist index
    logger.info(f"Persisting index to: {config.VECTOR_STORE_DIR}")
    index.storage_context.persist(persist_dir=str(config.VECTOR_STORE_DIR))

    logger.info("✅ Index created and saved successfully")


def main() -> None:
    """Main entry point for index creation script."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )

    try:
        create_index()
    except Exception as e:
        logger.error(f"Failed to create index: {e}")
        raise


if __name__ == "__main__":
    main()
