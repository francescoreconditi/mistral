# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Mistral SQL Assistant** - an AI-powered application that translates natural language questions into SQL queries using a RAG (Retrieval-Augmented Generation) pattern. The system builds a persistent vector index from a SQL schema file and uses it to provide context to an LLM for intelligent SQL generation.

**Tech Stack:**
- **UI**: Streamlit web framework
- **LLM**: OpenAI (GPT-4o-mini or GPT-4o via API)
- **Embeddings**: OpenAI Embeddings (text-embedding-3-small via API)
- **Vector Store**: LlamaIndex with disk persistence
- **Package Manager**: uv (modern, fast Python package manager)

## Development Commands

### Docker (Recommended)

```bash
# Build and start application
docker-compose up --build

# Start in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down

# Access container shell
docker-compose exec mistral-app bash

# Regenerate index after schema changes
docker-compose exec mistral-app uv run python scripts/create_index.py
```

App runs at `http://localhost:8501`

### Local Development

```bash
# Install dependencies
uv sync                    # Production deps
uv sync --extra dev        # Include dev deps

# Run application
uv run python scripts/run_app.py    # Via script
mistral-app                         # Via console script
uv run streamlit run src/mistral/ui/app.py  # Direct

# Create/regenerate vector index
uv run python scripts/create_index.py    # Via script
mistral-create-index                     # Via console script
```

### Testing & Quality

```bash
# Run all tests
uv run pytest

# Run single test file
uv run pytest tests/test_auth.py

# Run specific test
uv run pytest tests/test_auth.py::TestAuthentication::test_authenticate_with_config_token

# Coverage
uv run pytest --cov=mistral --cov-report=html

# Linting and formatting
uv run ruff check src/          # Lint
uv run ruff format src/         # Format
uv run ruff check --fix src/    # Auto-fix

# Type checking
uv run mypy src/

# Pre-commit hooks
uv run pre-commit install
uv run pre-commit run --all-files
```

### Package Management

```bash
uv add <package>           # Add production dependency
uv add --dev <package>     # Add dev dependency
uv remove <package>        # Remove dependency
uv lock                    # Update lockfile
```

## Architecture & Key Patterns

### Two-Phase Architecture

The system operates in two distinct phases:

**Phase 1: Index Creation** (one-time or when schema changes)
```
data/schema.sql → indexer.py → Vector Embeddings → data/db_index/ (persistent)
```

**Phase 2: Query Execution** (every user query)
```
User Question → HF Embeddings → Semantic Search (vector store) →
Retrieved Context + Question → Ollama LLM → Generated SQL
```

### Configuration Validation

`config.py::validate()` is called early in both engine and indexer to verify:
- `OPENAI_API_KEY` exists (required)
- `data/schema.sql` exists
- Creates necessary directories

No separate authentication step needed - OpenAI uses API key directly.

### Configuration Validation

`config.py::validate()` is called early in both phases to:
- Verify `HUGGINGFACE_TOKEN` exists (required)
- Check `data/schema.sql` exists
- Create necessary directories

### The schema.sql Pattern

`data/schema.sql` serves dual purposes:
1. **Database structure**: Standard SQL table definitions
2. **LLM instructions**: SQL comments that guide query generation (e.g., temporal filter patterns)

When modifying schema.sql, embed domain-specific instructions as SQL comments - the LLM will use them during generation.

### Persistent Vector Store

The vector index is created once and persisted to `data/db_index/`. This means:
- First run requires index creation (`mistral-create-index`)
- Subsequent runs load from disk (fast)
- Must regenerate if `data/schema.sql` changes
- In Docker, survives container restarts via volume mounting

### Session State Pattern

Streamlit UI uses session state to cache the query engine:
- `st.session_state.query_engine` loaded once per session
- `st.session_state.history` tracks query/response pairs
- Avoids reloading expensive LLM/embedding models on every interaction

### Entry Points

Two console scripts defined in `pyproject.toml`:
- `mistral-app` → `mistral.ui.app:main`
- `mistral-create-index` → `mistral.core.indexer:main`

## Environment Setup

### Prerequisites

1. **Python 3.10+** required
2. **OpenAI API Key** required:
   - Get from https://platform.openai.com/api-keys
   - Set in `.env` file as `OPENAI_API_KEY`

### Configuration

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
# Edit .env with your settings
```

**Critical variables:**
- `OPENAI_API_KEY` - **Required**, no default
- `OPENAI_MODEL` - Default: `gpt-4o-mini` (recommended for cost/performance)
- `OPENAI_EMBEDDING_MODEL` - Default: `text-embedding-3-small`
- `OPENAI_TEMPERATURE` - Default: `0.0` (deterministic for SQL generation)

### First-Time Setup

**With Docker (recommended):**
```bash
# 1. Configure .env if needed
# 2. Start application
docker-compose up --build
# Index is created automatically if missing
```

**Local:**
```bash
# 1. Install dependencies
uv sync --extra dev

# 2. Configure .env
cp .env.example .env
# Edit .env with your token

# 3. Create index
mistral-create-index

# 4. Run app
mistral-app
```

## Module Responsibilities

### Core Layer (`src/mistral/core/`)

- **`engine.py`**: Initializes and returns query engine. Loads LLM (Ollama), embeddings (HF), and vector store from disk. Called once per Streamlit session.
- **`indexer.py`**: Creates vector index from `data/schema.sql`. Generates embeddings, persists to `data/db_index/`. Run when schema changes.

### UI Layer (`src/mistral/ui/`)

- **`app.py`**: Main Streamlit application orchestration. Manages session state, processes queries, displays results.
- **`components.py`**: Reusable UI components (header, input, history display, SQL syntax highlighting, copy-to-clipboard).

### Utils & Config

- **`config.py`**: Centralized configuration from environment variables. Validates settings, manages paths.
- **`utils/auth.py`**: HuggingFace Hub authentication. Must be called before any HF model operations.

## Docker Architecture

**Volumes:**
- `./data:/app/data` - Persistent schema and vector indices
- `./src:/app/src` - Hot reload for development
- `./.env:/app/.env:ro` - Read-only configuration

**Key features:**
- Non-root user (`mistral`) for security
- Health check on Streamlit endpoint
- `uv` for fast dependency installation
- Hot reload: code changes reflected immediately

## Testing Strategy

Tests use `pytest` with mocking for external services:
- `tests/test_auth.py` - HuggingFace authentication flows
- `tests/test_config.py` - Configuration validation
- `tests/conftest.py` - Shared fixtures (mock_config, mock_query_engine)

**Coverage expectations:**
- Core modules (`auth.py`, `config.py`): 90-100%
- Engine/indexer: 70-80% (integration-heavy)
- UI components: 60-70% (Streamlit-dependent)

## Common Workflows

### Modifying the SQL Schema

```bash
# 1. Edit data/schema.sql (add tables, update instructions)
# 2. Regenerate index
mistral-create-index
# 3. Restart app (if running)
```

### Adding a New Dependency

```bash
uv add <package>           # Production
uv add --dev <package>     # Development
# Automatically updates pyproject.toml and uv.lock
```

### Debugging Query Generation

The LLM sees:
1. Retrieved context from vector store (relevant schema chunks)
2. User's natural language question
3. Any SQL comment instructions from schema.sql

To improve results, add guidance as SQL comments in `data/schema.sql`.

### Switching Between OpenAI Models

Edit `.env`:
```bash
# For cost optimization (recommended)
OPENAI_MODEL=gpt-4o-mini          # ~$0.00008/query

# For best quality
OPENAI_MODEL=gpt-4o               # ~$0.0025/query

# For embedding optimization
OPENAI_EMBEDDING_MODEL=text-embedding-3-small  # Smaller, faster
OPENAI_EMBEDDING_MODEL=text-embedding-3-large  # More accurate
```

**Note**: Changing embedding model requires regenerating the index.
