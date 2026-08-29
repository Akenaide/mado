import asyncio
from models.utils import pagination
from config import get_settings
import typing
import strawberry

from meili_client import get_meili_client

settings = get_settings()


@strawberry.type
class CategoryStat:
    name: str
    count: int


@strawberry.type
class SetStats:
    total: int
    by_product_type: list[CategoryStat]


@strawberry.type
class Set:
    id: str
    release_date: str
    release_year: int
    title: str
    title_codes: typing.List[str]
    image_path: typing.Optional[str] = None
    image_url: typing.Optional[str] = None
    set_code: str
    licence_code: typing.Optional[str] = None
    product_type: str = ""


async def get_sets(
    page_size: int = settings.page_size,
    page_num: int = 1,
) -> typing.List[Set]:
    client = get_meili_client()

    def _search():
        return client.index("sets").search(
            "", pagination(page_size=page_size, page_num=page_num)
        )

    result = await asyncio.to_thread(_search)
    return [Set(**hit) for hit in result["hits"]]


async def search_sets(
    query: str,
    page_size: int = settings.page_size,
    page_num: int = 1,
) -> typing.List[Set]:
    client = get_meili_client()

    def _search():
        return client.index("sets").search(
            query, pagination(page_size=page_size, page_num=page_num)
        )

    result = await asyncio.to_thread(_search)
    return [Set(**hit) for hit in result["hits"]]


async def get_set_stats(query: str = ""):
    client = get_meili_client()

    def _search():
        return client.index("sets").search(
            query, {"limit": 0, "facets": ["product_type"]}
        )

    result = await asyncio.to_thread(_search)
    dist = result.get("facetDistribution", {}).get("product_type", {})
    # product_type is always set by the importer but may be "" for legacy docs — skip those
    categories = [CategoryStat(name=k, count=v) for k, v in dist.items() if k]
    return SetStats(total=sum(c.count for c in categories), by_product_type=categories)
