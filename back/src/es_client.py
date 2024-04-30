import os

from elasticsearch import Elasticsearch

from config import get_settings

settings = get_settings()

API_KEY_PATH = os.path.join(settings.base_dir, "es_api_key")


def get_es_client() -> Elasticsearch:
    if not os.path.exists(API_KEY_PATH):
        create_es_api_key()

    with open(API_KEY_PATH, "r") as key_file:
        api_key = key_file.readline().strip()

    es = Elasticsearch(
        settings.es_url,
        ca_certs=settings.es_cert_path,
        api_key=api_key,
    )

    return es


def create_es_api_key() -> None:
    # Call ES to get API and write it in a file
    es = Elasticsearch(
        settings.es_url,
        ca_certs=settings.es_cert_path,
        basic_auth=(settings.elastic_username, settings.elastic_password),
    )
    response = es.security.create_api_key(name="back")
    api_key = response.body["encoded"]

    with open(API_KEY_PATH, "w") as f:
        f.write(api_key)

    return api_key
