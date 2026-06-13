import asyncio
from models.utils import pagination
from config import get_settings
import typing
import strawberry

from meili_client import get_meili_client

settings = get_settings()


@strawberry.type
class Set:
    id: str
    release_date: str
    release_year: int
    title: str
    image_path: typing.Optional[str] = None
    image_url: typing.Optional[str] = None
    set_code: str
    product_type: str


async def get_sets(
    page_size: int = settings.page_size,
    page_num: int = 1,
) -> typing.List[Set]:
    client = get_meili_client()

    # ⚡ Bolt: Offload synchronous Meilisearch call to a separate thread to prevent blocking the async event loop.
    def fetch():
        return client.index("sets").search(
            "", pagination(page_size=page_size, page_num=page_num)
        )

    result = await asyncio.to_thread(fetch)
    return [Set(**dict(hit)) for hit in result["hits"]]


async def search_sets(
    query: str,
    page_size: int = settings.page_size,
    page_num: int = 1,
) -> typing.List[Set]:
    client = get_meili_client()

    # ⚡ Bolt: Offload synchronous Meilisearch call to a separate thread to prevent blocking the async event loop.
    def search():
        return client.index("sets").search(
            query, pagination(page_size=page_size, page_num=page_num)
        )

    result = await asyncio.to_thread(search)
    return [Set(**dict(hit)) for hit in result["hits"]]
