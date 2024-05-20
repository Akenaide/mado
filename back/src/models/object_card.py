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


"""
Elasticsearch mappings for 'cards' documents
"""
es_mappings = {
    "properties": {
        "id": {"type": "keyword"},
        "set": {"type": "keyword"},
        "setName": {"type": "keyword"},
        "name": {
            "type": "text",
            "fields": {"keyword": {"type": "keyword", "ignore_above": 256}},
        },
        "imageURL": {"type": "keyword"},
        "cardType": {"type": "keyword"},
        "color": {"type": "keyword"},
        "level": {"type": "integer"},
        "cost": {"type": "integer"},
        "power": {"type": "integer"},
        "soul": {"type": "integer"},
        "rarity": {"type": "keyword"},
        "triggers": {"properties": {"trigger": {"type": "keyword"}}},
        "abilities": {"properties": {"ability": {"type": "text"}}},
        "specialAttribs": {"properties": {"specialAttrib": {"type": "keyword"}}},
        "language": {"type": "keyword"},
    }
}
