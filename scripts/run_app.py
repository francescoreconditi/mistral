#!/usr/bin/env python3
"""Entry point script for running the Streamlit application."""

import sys
import subprocess
from pathlib import Path

# Add src to Python path
src_path = Path(__file__).parent.parent / "src"
sys.path.insert(0, str(src_path))


def main() -> None:
    """Run the Streamlit application."""
    try:
        # Run streamlit with the app module
        subprocess.run([
            "streamlit", "run", 
            str(src_path / "mistral" / "ui" / "app.py"),
            "--server.address", "localhost",
            "--server.port", "8501"
        ], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running Streamlit app: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nApplication stopped by user")
        sys.exit(0)


if __name__ == "__main__":
    main()