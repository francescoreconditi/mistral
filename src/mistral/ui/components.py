"""UI components for Streamlit application."""

import html
import re
from typing import Dict, List

import streamlit as st


def setup_page_config() -> None:
    """Configure Streamlit page settings."""
    st.set_page_config(page_title="Assistente SQL", page_icon="🧠")


def setup_custom_css() -> None:
    """Apply custom CSS styles to the page."""
    st.markdown(
        """
        <style>
        .copy-button {
            background-color: #f0f2f6;
            border: 1px solid #ccc;
            padding: 6px 10px;
            border-radius: 4px;
            font-size: 0.9rem;
            cursor: pointer;
            margin-top: 10px;
        }

        .copy-button:hover {
            background-color: #e0e0e0;
        }
        </style>
        """,
        unsafe_allow_html=True,
    )


def display_header() -> None:
    """Display the main page header."""
    st.title("🧠 Assistente SQL con indice persistente")


def get_user_input() -> str:
    """Get user query input."""
    return st.text_area("Scrivi una richiesta:", height=100)


def display_response_time(elapsed_time: float) -> None:
    """Display response generation time."""
    st.success(f"Risposta generata in {elapsed_time:.2f} secondi ✅")


def display_history(history: List[Dict[str, str]]) -> None:
    """Display query history with responses.

    Args:
        history: List of query-response pairs
    """
    if not history:
        return

    st.subheader("📜 Cronologia")

    for i, item in enumerate(reversed(history)):
        with st.expander(f"❓ Domanda: {item['domanda']}", expanded=False):
            st.markdown(f"⏱️ **Tempo di risposta:** `{item['tempo']}`")

            # Display full response in text area
            st.text_area(
                "Risposta:", value=item["risposta"], height=200, key=f"txt_{i}"
            )

            # Extract and display SQL code blocks
            _display_sql_code_blocks(item["risposta"])

            # Add copy button
            _add_copy_button(item["risposta"])


def _display_sql_code_blocks(response: str) -> None:
    """Extract and display SQL code blocks from response.

    Args:
        response: Response text containing potential SQL code blocks
    """
    match = re.search(r"```sql(.*?)```", response, re.DOTALL)
    if match:
        sql_code = match.group(1).strip()
        st.code(sql_code, language="sql")


def _add_copy_button(response: str) -> None:
    """Add copy button for response text.

    Args:
        response: Response text to copy
    """
    # Clean response for copying (remove markdown code blocks)
    cleaned = re.sub(r"```.*?```", "", response, flags=re.DOTALL)
    escaped = html.escape(cleaned).replace("`", "\\`")

    st.markdown(
        f"""
        <button class="copy-button" onclick="navigator.clipboard.writeText(`{escaped}`)">
            📋 Copia la risposta
        </button>
        """,
        unsafe_allow_html=True,
    )
