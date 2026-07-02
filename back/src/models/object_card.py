import asyncio
import dataclasses
import typing
import strawberry

from meili_client import get_meili_client
from models.utils import pagination
from config import get_settings

settings = get_settings()


@strawberry.type
class Card:
    id_card: str
    cardcode: str
    set_code: str
    set: str
    set_name: str
    side: str
    release: str
    name: str
    image_url: str
    image_path: str
    rarity: str
    level: int
    cost: int
    power: int
    soul: int
    color: str
    card_type: str
    special_attribute: typing.List[str]
    abilities: typing.List[str]
    triggers: typing.List[str]
    flavour_text: str
    expansionId: int
    language: str


BASE_RARITIES = ["RR", "R", "U", "C", "CC", "CR"]


# Cache dataclass fields at module load time to avoid recomputing it inside the request loop,
# which eliminates a hidden CPU bottleneck on every query
_CARD_FIELDS = {f.name for f in dataclasses.fields(Card)}


async def get_cards(
    set_code: str,
    page_size: int = settings.page_size,
    page_num: int = 1,
    base_only: bool = False,
) -> typing.List[Card]:
    client = get_meili_client()
    filters = [f'set_code = "{set_code}"']
    if base_only:
        rarity_filter = " OR ".join(f'rarity = "{r}"' for r in BASE_RARITIES)
        filters.append(f"({rarity_filter})")

    # Run the synchronous Meilisearch call in a thread pool to avoid blocking the FastAPI event loop
    def _search():
        return client.index("cards").search(
            "",
            {
                "filter": " AND ".join(filters),
                "sort": ["id_card:asc"],
                **pagination(page_size=page_size, page_num=page_num),
            },
        )

    result = await asyncio.to_thread(_search)

    return [
        Card(**{k: v for k, v in hit.items() if k in _CARD_FIELDS})
        for hit in result["hits"]
    ]
