import typing
from pathlib import Path

from es_import import utilities

def import_cards(cards_dir: str, client: utilities.ESClient) -> None:
    """
    Recursively import all .json files in the directory
    """
    for path in Path(cards_dir).rglob('*.json'):
        _import_card(path, client)


def _import_card(cards_dir: str, client: utilities.ESClient) -> None:
    """
    Import a single .json card
    """
    card_json = utilities.get_json(cards_dir)
    es_json = _transform_card_json(card_json)
    resp = client.get_client.index(index="cards", body=es_json, id=es_json['id'])
    # Print errors
    if resp['result'] != 'created' and resp['result'] != 'updated':
        print(resp)


def _transform_card_json(card_json: typing.Any) -> dict[str, typing.Any]:
    """
    Transform a wsoffcli-format JSON card to our ES format
    Arrays need to be separated this way to allow full-text search
    """
    es_json = {
        "id": card_json["cardcode"],
        "set": card_json["set"],
        "setName": card_json["setName"],
        "name": card_json["jpName"],
        "imageURL": card_json["imageURL"],
        "cardType": card_json["cardType"],
        "color": card_json["colour"],
        "level": card_json["level"],
        "cost": card_json["cost"],
        "power": card_json["power"],
        "soul": card_json["soul"],
        "rarity": card_json["rarity"],
        "triggers": [],
        "abilities": [],
        "specialAttribs": [],
        "language": "JP"
    }
    for trigger in card_json['trigger']:
        es_json["triggers"].append({"trigger": trigger})
    for ability in card_json['ability']:
        es_json["abilities"].append({"ability": ability})
    for specialAttrib in card_json['specialAttrib']:
        es_json["specialAttribs"].append({"specialAttrib": specialAttrib})

    return es_json