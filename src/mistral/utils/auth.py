"""Authentication utilities for HuggingFace."""

import logging
from typing import Optional

from huggingface_hub import login

from mistral.config import config

logger = logging.getLogger(__name__)


def authenticate_huggingface(token: Optional[str] = None) -> None:
    """Authenticate with HuggingFace Hub.
    
    Args:
        token: HuggingFace token. If None, uses config.HUGGINGFACE_TOKEN
        
    Raises:
        ValueError: If no token is provided and none is found in config
    """
    hf_token = token or config.HUGGINGFACE_TOKEN
    
    if not hf_token:
        raise ValueError(
            "HuggingFace token is required. "
            "Please set HUGGINGFACE_TOKEN environment variable or provide token parameter"
        )
    
    try:
        login(token=hf_token)
        logger.info("Successfully authenticated with HuggingFace Hub")
    except Exception as e:
        logger.error(f"Failed to authenticate with HuggingFace Hub: {e}")
        raise