#!/usr/bin/env python3
"""Entry point script for creating the vector index."""

import sys
from pathlib import Path

# Add src to Python path
src_path = Path(__file__).parent.parent / "src"
sys.path.insert(0, str(src_path))


def main() -> None:
    """Create the vector index."""
    from mistral.core.indexer import main as indexer_main

    try:
        indexer_main()
    except Exception as e:
        print(f"Error creating index: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
