import os
from functools import lru_cache

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    base_dir: str = os.path.dirname(os.path.abspath(__file__))
    medias_dir: str = "/medias"
    cards_dir: str = "/data/cards"
    set_file: str = "/data/products.json"
    meili_url: str = "http://meilisearch:7700"
    meili_master_key: str
    page_size: int = 20
    allowed_origins: list[str] = ["http://localhost"]


@lru_cache
def get_settings() -> Settings:
    # https://fastapi.tiangolo.com/advanced/settings/?h=config#settings-in-a-dependency
    return Settings()
