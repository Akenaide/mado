import typing
import strawberry

from meili_client import get_meili_client


@strawberry.type
class Set:
    release_date: str
    release_year: int
    title: str
    image64: typing.Optional[str] = None
    image_path: typing.Optional[str] = None
    image_url: typing.Optional[str] = None
    set_code: str


def get_sets() -> typing.List[Set]:
    client = get_meili_client()
    result = client.index("sets").search("")
    return [Set(**dict(hit)) for hit in result["hits"]]


def search_sets(query: str) -> typing.List[Set]:
    client = get_meili_client()
    result = client.index("sets").search(query)
    return [Set(**dict(hit)) for hit in result["hits"]]
