import typing
import strawberry

from meili_client import get_meili_client


@strawberry.type
class Set:
    release_date: str
    release_year: int
    title: str
    image64: typing.Optional[str] = None
    image_url: str
    set_code: str


def get_sets() -> typing.List[Set]:
    client = get_meili_client()
    result = client.index("sets").get_documents()
    return [Set(**doc) for doc in result.results]
