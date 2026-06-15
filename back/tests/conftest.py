import os
import tempfile

os.environ.setdefault("MEILI_MASTER_KEY", "test")
os.environ.setdefault("MEDIAS_DIR", tempfile.gettempdir())

import pytest
from unittest.mock import MagicMock, patch
from starlette.testclient import TestClient

from main import app


@pytest.fixture
def mock_meili():
    mock_client = MagicMock()
    with patch("models.object_set.get_meili_client", return_value=mock_client):
        yield mock_client


@pytest.fixture
def mock_meili_cards():
    mock_client = MagicMock()
    with patch("models.object_card.get_meili_client", return_value=mock_client):
        yield mock_client


@pytest.fixture
def client():
    return TestClient(app)
