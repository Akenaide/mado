from functools import cached_property
import json

from elasticsearch import Elasticsearch
from es_import.env_file import EnvFile

def get_json(filename: str):
    """
    Open and parse a JSON file
    """
    with open(filename, "r", encoding='utf-8') as json_file:
        return json.load(json_file)


class ESClient:
    def __init__(self, cert_path: str, env_file: EnvFile, endpoint: str) -> None:
        """
        Initialize the ElasticSearch client

        Parameters
        ----------
            cert_path : str
                Path of the HTTPS certificate of the ES server
            env_file : EnvFile
                The .env file containing the ES password
            endpoint : str
                URL of the ES server (e.g. https://localhost:9200)
        """
        self._cert_path = cert_path
        self._password = env_file.get_env("ELASTIC_PASSWORD")
        self._endpoint = endpoint

    @cached_property
    def get_client(self) -> Elasticsearch:
        """
        Create an ES client on the first call
        Return the cached result on subsequent calls
        """
        return Elasticsearch(
            self._endpoint,
            basic_auth=('elastic', self._password),
            #api_key=(self._token['id'], self._token['api_key']),
            ca_certs= self._cert_path, # /usr/share/elasticsearch/config/certs/ca/ca.crt
        )