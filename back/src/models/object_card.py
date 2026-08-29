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
    related_cards: typing.List[str] = dataclasses.field(default_factory=list)


BASE_RARITIES = ["RR", "R", "U", "C", "CC", "CR", "TD"]

# Cache dataclasses.fields to avoid computing it on every request
_CARD_FIELDS = {f.name for f in dataclasses.fields(Card)}


async def get_cards_by_ids(id_cards: typing.List[str]) -> typing.List[Card]:
    if not id_cards:
        return []
    client = get_meili_client()
    filter_val = " OR ".join(f'id_card = "{i}"' for i in id_cards)

    def _search():
        return client.index("cards").search(
            "", {"filter": filter_val, "limit": len(id_cards), "sort": ["id_card:asc"]}
        )

    result = await asyncio.to_thread(_search)
    return [
        Card(**{k: v for k, v in hit.items() if k in _CARD_FIELDS})
        for hit in result["hits"]
    ]


async def get_card(id_card: str) -> typing.Optional[Card]:
    client = get_meili_client()

    def _search():
        return client.index("cards").search(
            "", {"filter": f'id_card = "{id_card}"', "limit": 1}
        )

    result = await asyncio.to_thread(_search)
    hits = result["hits"]
    if not hits:
        return None
    return Card(**{k: v for k, v in hits[0].items() if k in _CARD_FIELDS})


def _quick_filters(
    levels: typing.Optional[typing.List[int]],
    card_types: typing.Optional[typing.List[str]],
    costs: typing.Optional[typing.List[int]],
    triggers: typing.Optional[typing.List[str]],
) -> typing.List[str]:
    extra = []
    if levels:
        extra.append("(" + " OR ".join(f"level = {lvl}" for lvl in levels) + ")")
    if card_types:
        extra.append(
            "(" + " OR ".join(f'card_type = "{ct}"' for ct in card_types) + ")"
        )
    if costs:
        parts = [("cost >= 3" if c == -1 else f"cost = {c}") for c in costs]
        extra.append("(" + " OR ".join(parts) + ")")
    if triggers:
        extra.append("(" + " OR ".join(f'triggers = "{t}"' for t in triggers) + ")")
    return extra


async def search_cards(
    set_code: str,
    query: str = "",
    page_size: int = settings.page_size,
    page_num: int = 1,
    base_only: bool = False,
    levels: typing.Optional[typing.List[int]] = None,
    card_types: typing.Optional[typing.List[str]] = None,
    costs: typing.Optional[typing.List[int]] = None,
    triggers: typing.Optional[typing.List[str]] = None,
) -> typing.List[Card]:
    client = get_meili_client()
    filters = [f'set_code = "{set_code}"']
    if base_only:
        rarity_filter = " OR ".join(f'rarity = "{r}"' for r in BASE_RARITIES)
        filters.append(f"({rarity_filter})")
    filters.extend(_quick_filters(levels, card_types, costs, triggers))

    def _search():
        return client.index("cards").search(
            query,
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


async def get_cards(
    set_code: str,
    page_size: int = settings.page_size,
    page_num: int = 1,
    base_only: bool = False,
    levels: typing.Optional[typing.List[int]] = None,
    card_types: typing.Optional[typing.List[str]] = None,
    costs: typing.Optional[typing.List[int]] = None,
    triggers: typing.Optional[typing.List[str]] = None,
) -> typing.List[Card]:
    client = get_meili_client()
    filters = [f'set_code = "{set_code}"']
    if base_only:
        rarity_filter = " OR ".join(f'rarity = "{r}"' for r in BASE_RARITIES)
        filters.append(f"({rarity_filter})")
    filters.extend(_quick_filters(levels, card_types, costs, triggers))

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
