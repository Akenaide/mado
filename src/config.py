import os
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    base_dir: str = os.path.dirname(os.path.abspath(__file__))
    cards_dir: str = "/data/cards"
    es_cert_path: str = "/certs/ca/ca.crt"
    es_url: str = "https://es01:9200/"
    elastic_username: str = "elastic"
    elastic_password: str

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


@lru_cache
def get_settings():
    # https://fastapi.tiangolo.com/advanced/settings/?h=config#settings-in-a-dependency
    return Settings()
