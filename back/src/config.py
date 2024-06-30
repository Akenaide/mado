import os
from functools import lru_cache

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    base_dir: str = os.path.dirname(os.path.abspath(__file__))
    cards_dir: str = "/data/cards"
    set_file: str = "/data/products.json"
    es_cert_path: str = "/certs/ca/ca.crt"
    es_url: str = "https://es01:9200/"
    elastic_username: str = "elastic"
    elastic_password: str
    set_index: str = "sets"
    card_index: str = "cards"


@lru_cache
def get_settings():
    # https://fastapi.tiangolo.com/advanced/settings/?h=config#settings-in-a-dependency
    return Settings()
