"""Main Streamlit application for Mistral SQL Assistant."""

import logging
import time
from typing import Dict, List

import streamlit as st

from mistral.core.engine import load_query_engine
from mistral.ui.components import (
    display_header,
    display_history,
    display_response_time,
    get_user_input,
    setup_custom_css,
    setup_page_config,
)

logger = logging.getLogger(__name__)


def initialize_session_state() -> None:
    """Initialize Streamlit session state variables."""
    if "query_engine" not in st.session_state:
        with st.spinner("Caricamento del query engine..."):
            st.session_state.query_engine = load_query_engine()

    if "history" not in st.session_state:
        st.session_state.history: List[Dict[str, str]] = []


def process_user_query(user_query: str) -> None:
    """Process user query and update session state.

    Args:
        user_query: User's input query
    """
    if not user_query.strip():
        return

    with st.spinner("Generazione in corso..."):
        start_time = time.time()

        try:
            response = st.session_state.query_engine.query(user_query)
            elapsed = time.time() - start_time

            # Add to history
            st.session_state.history.append(
                {
                    "domanda": user_query,
                    "risposta": str(response),
                    "tempo": f"{elapsed:.2f} secondi",
                }
            )

            display_response_time(elapsed)

        except Exception as e:
            logger.error(f"Error processing query: {e}")
            st.error(f"Errore durante la generazione: {str(e)}")


def main() -> None:
    """Main application entry point."""
    # Setup logging
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )

    try:
        # Setup page
        setup_page_config()
        setup_custom_css()
        display_header()

        # Initialize session
        initialize_session_state()

        # User input
        user_query = get_user_input()

        # Process query
        if st.button("Genera query"):
            process_user_query(user_query)

        # Display history
        display_history(st.session_state.history)

    except Exception as e:
        logger.error(f"Application error: {e}")
        st.error(f"Errore nell'applicazione: {str(e)}")
        st.error("Controlla i log per maggiori dettagli.")


if __name__ == "__main__":
    main()
