import meilisearch
from functools import lru_cache

from config import get_settings

settings = get_settings()


@lru_cache()
def get_meili_client() -> meilisearch.Client:
    return meilisearch.Client(settings.meili_url, settings.meili_master_key)
