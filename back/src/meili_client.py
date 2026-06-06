import meilisearch

from config import get_settings

settings = get_settings()


def get_meili_client() -> meilisearch.Client:
    return meilisearch.Client(settings.meili_url, settings.meili_master_key)
