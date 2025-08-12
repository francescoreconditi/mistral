"""Vector index creation for Mistral SQL Assistant."""

import logging
from pathlib import Path

from langchain_community.llms import Ollama
from llama_index import ServiceContext, SimpleDirectoryReader, VectorStoreIndex
from llama_index.embeddings import HuggingFaceEmbedding
from llama_index.llms.langchain import LangChainLLM

from mistral.config import config
from mistral.utils.auth import authenticate_huggingface

logger = logging.getLogger(__name__)


def create_index() -> None:
    """Create vector index from SQL schema file.
    
    Raises:
        FileNotFoundError: If schema file doesn't exist
        ValueError: If authentication fails
    """
    logger.info("Starting index creation...")
    
    # Authenticate with HuggingFace
    authenticate_huggingface()
    
    # Validate configuration
    config.validate()
    
    # Initialize components
    logger.info(f"Initializing LLM with model: {config.OLLAMA_MODEL} at {config.OLLAMA_HOST}")
    llm = LangChainLLM(llm=Ollama(model=config.OLLAMA_MODEL, base_url=f"http://{config.OLLAMA_HOST}"))
    
    logger.info(f"Initializing embedding model: {config.EMBEDDING_MODEL} on device: {config.DEVICE}")
    embed_model = HuggingFaceEmbedding(
        model_name=config.EMBEDDING_MODEL,
        device=config.DEVICE,
    )
    
    service_context = ServiceContext.from_defaults(
        llm=llm, 
        embed_model=embed_model
    )
    
    # Load schema document
    logger.info(f"Loading schema from: {config.SCHEMA_FILE}")
    documents = SimpleDirectoryReader(
        input_files=[str(config.SCHEMA_FILE)]
    ).load_data()
    
    # Create index
    logger.info("Creating vector index...")
    index = VectorStoreIndex.from_documents(
        documents, 
        service_context=service_context
    )
    
    # Persist index
    logger.info(f"Persisting index to: {config.VECTOR_STORE_DIR}")
    index.storage_context.persist(persist_dir=str(config.VECTOR_STORE_DIR))
    
    logger.info("✅ Index created and saved successfully")


def main() -> None:
    """Main entry point for index creation script."""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    try:
        create_index()
    except Exception as e:
        logger.error(f"Failed to create index: {e}")
        raise


if __name__ == "__main__":
    main()