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
    # Optimization: Offload synchronous meilisearch call to a thread to prevent blocking the FastAPI/uvicorn event loop
    result = await asyncio.to_thread(
        client.index("sets").search,
        "",
        pagination(page_size=page_size, page_num=page_num),
    )
    return [Set(**dict(hit)) for hit in result["hits"]]


async def search_sets(
    query: str,
    page_size: int = settings.page_size,
    page_num: int = 1,
) -> typing.List[Set]:
    client = get_meili_client()
    # Optimization: Offload synchronous meilisearch call to a thread to prevent blocking the FastAPI/uvicorn event loop
    result = await asyncio.to_thread(
        client.index("sets").search,
        query,
        pagination(page_size=page_size, page_num=page_num),
    )
    return [Set(**dict(hit)) for hit in result["hits"]]
