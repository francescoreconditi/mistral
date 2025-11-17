"""Authentication utilities for Mistral SQL Assistant.

DEPRECATED: This module is deprecated and no longer used with OpenAI.
OpenAI authentication is handled via OPENAI_API_KEY environment variable.
"""

import logging
import warnings
from typing import Optional

logger = logging.getLogger(__name__)


def authenticate_huggingface(token: Optional[str] = None) -> None:
    """Deprecated: No longer needed with OpenAI.

    This function is deprecated and no longer performs any action.
    OpenAI uses OPENAI_API_KEY environment variable for authentication.

    Args:
        token: Unused parameter, kept for backward compatibility

    Deprecated:
        Since migration to OpenAI. This function will be removed in a future version.
    """
    warnings.warn(
        "authenticate_huggingface is deprecated and no longer used. "
        "OpenAI uses OPENAI_API_KEY environment variable for authentication.",
        DeprecationWarning,
        stacklevel=2,
    )
    logger.warning(
        "authenticate_huggingface called but is deprecated. "
        "Migration to OpenAI complete - this function does nothing."
    )
