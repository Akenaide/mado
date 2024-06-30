import typing
import strawberry

from config import get_settings
from es_client import get_es_client

settings = get_settings()


@strawberry.type
class Set:
    release_date: str
    title: str
    image64: str
    image_url: str
    set_code: str


def get_sets() -> typing.List[Set]:
    es = get_es_client()
    resp = es.search(index=settings.set_index)
    output = [Set(**hit["_source"]) for hit in resp["hits"]["hits"]]

    return output


set_es_mappings = {
    "properties": {
        "release_date": {
            "type": "date",
        },
        "title": {
            "type": "keyword",
        },
        "image64": {
            "type": "keyword",
        },
        "image_url": {
            "type": "keyword",
        },
        "set_code": {
            "type": "keyword",
        },
    }
}
