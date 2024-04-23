import typing
import strawberry

@strawberry.type
class Card:
    set_code: str
    name: str
    image64: str
    image_url: str
    id_card: str
    ability: typing.List[str]
    rarity: str
    level: int
    cost: int
    power: int
    soul: int
    color: str
    card_type: str
    special_attribute: typing.List[str]
    language: str
