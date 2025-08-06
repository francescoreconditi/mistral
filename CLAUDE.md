# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Mistral SQL Assistant application that uses LlamaIndex and Streamlit to create an interactive SQL query generation interface. The system builds and queries a persistent vector index from a SQL schema to provide intelligent SQL assistance.

## Architecture

- **main.py**: Streamlit web application that provides the user interface
- **engine.py**: Contains the query engine loader that initializes LLM and embedding models
- **create_index.py**: One-time script to build the vector index from the SQL schema
- **schema.sql**: SQL schema file that serves as the knowledge base for the assistant
- **db_index/**: Persistent storage directory for the LlamaIndex vector store

## Technology Stack

- **Frontend**: Streamlit web framework
- **LLM**: Ollama with Mistral model (CPU-based)
- **Embeddings**: HuggingFace sentence-transformers/all-MiniLM-L6-v2 (GPU-accelerated)
- **Vector Store**: LlamaIndex VectorStoreIndex with persistent storage
- **Package Manager**: uv (modern Python package manager)

## Development Commands

### Environment Setup
```bash
uv sync                    # Install dependencies and sync environment
```

### Running the Application
```bash
uv run streamlit run main.py     # Start the Streamlit web application
```

### Index Management
```bash
uv run python create_index.py    # Rebuild the vector index from schema.sql
```

### Package Management
```bash
uv add <package>          # Add a new dependency
uv remove <package>       # Remove a dependency
uv lock                   # Update the lockfile
```

## Key Components

### Query Engine (engine.py:15)
The `load_query_engine()` function initializes:
- Ollama/Mistral LLM for text generation
- HuggingFace embeddings with CUDA GPU acceleration
- Persistent vector index loading from `./db_index`

### Index Creation (create_index.py:23)
Reads the SQL schema file and creates a searchable vector index that persists to disk for fast subsequent loads.

### UI Features (main.py)
- Real-time query generation with response timing
- SQL code extraction and syntax highlighting
- Query history with expandable responses
- Copy-to-clipboard functionality for generated responses

## Important Notes

- The application requires CUDA GPU for optimal embedding performance
- Ollama must be installed separately and the Mistral model pulled
- The vector index is built once and persists between sessions
- HuggingFace token is hardcoded in engine.py and create_index.py (consider moving to environment variables)

## GPU Requirements

The embedding model is configured to use CUDA (`device="cuda"` in engine.py:22 and create_index.py:18). Ensure CUDA is available or modify to use CPU if needed.