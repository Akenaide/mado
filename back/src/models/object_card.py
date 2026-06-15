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


def get_cards(
    set_code: str,
    page_size: int = settings.page_size,
    page_num: int = 1,
) -> typing.List[Card]:
    client = get_meili_client()
    result = client.index("cards").search(
        "",
        {
            "filter": f'set_code = "{set_code}"',
            "sort": ["id_card:asc"],
            **pagination(page_size=page_size, page_num=page_num),
        },
    )
    fields = {f.name for f in dataclasses.fields(Card)}
    return [
        Card(**{k: v for k, v in hit.items() if k in fields}) for hit in result["hits"]
    ]
