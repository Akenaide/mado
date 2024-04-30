import typing
import strawberry

from es_client import get_es_client


@strawberry.type
class Set:
    release_date: str
    title: str
    image64: str
    image_url: str
    set_code: str


def get_sets() -> typing.List[Set]:
    SET_INDEX = "search-set"
    es = get_es_client()
    resp = es.search(index=SET_INDEX)
    output = [Set(**hit["_source"]) for hit in resp["hits"]["hits"]]

    return output
