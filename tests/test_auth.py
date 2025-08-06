"""Tests for authentication utilities."""

import pytest
from unittest.mock import patch, MagicMock

from mistral.utils.auth import authenticate_huggingface


class TestAuthentication:
    """Test authentication functionality."""
    
    @patch('mistral.utils.auth.login')
    @patch('mistral.utils.auth.config')
    def test_authenticate_with_config_token(self, mock_config, mock_login):
        """Test authentication using token from config."""
        mock_config.HUGGINGFACE_TOKEN = "config_token"
        
        authenticate_huggingface()
        
        mock_login.assert_called_once_with(token="config_token")
    
    @patch('mistral.utils.auth.login')
    def test_authenticate_with_parameter_token(self, mock_login):
        """Test authentication using token parameter."""
        authenticate_huggingface(token="param_token")
        
        mock_login.assert_called_once_with(token="param_token")
    
    @patch('mistral.utils.auth.config')
    def test_authenticate_no_token_raises_error(self, mock_config):
        """Test authentication raises error when no token is available."""
        mock_config.HUGGINGFACE_TOKEN = None
        
        with pytest.raises(ValueError, match="HuggingFace token is required"):
            authenticate_huggingface()
    
    @patch('mistral.utils.auth.login')
    def test_authenticate_login_failure(self, mock_login):
        """Test authentication handles login failure."""
        mock_login.side_effect = Exception("Login failed")
        
        with pytest.raises(Exception, match="Login failed"):
            authenticate_huggingface(token="test_token")