import os
from functools import lru_cache

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    base_dir: str = os.path.dirname(os.path.abspath(__file__))
    es_cert_path: str = "/certs/ca/ca.crt"
    es_url: str = "https://es01:9200/"
    elastic_username: str = ""
    elastic_password: str = ""


@lru_cache
def get_settings():
    # https://fastapi.tiangolo.com/advanced/settings/?h=config#settings-in-a-dependency
    return Settings()
