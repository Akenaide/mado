#!/usr/bin/env python3
import json
from pathlib import Path
import typing

import fixpath as _
from config import get_settings
from es_client import get_es_client

"""
Recursively import all .json files from the cards directory
"""

settings = get_settings()
stats = {"created": 0, "updated": 0, "failed": 0}


def _import_card(card_path: str, client) -> None:
    """
    Import a single .json card
    """
    with open(card_path, "r", encoding="utf-8") as json_file:
        card_json = json.load(json_file)
    es_json = _transform_card_json(card_json)
    resp = client.index(index="cards", body=es_json, id=es_json["id"])

    if resp["result"] in ["created", "updated"]:
        stats[resp["result"]] += 1
    else:
        stats["failed"] += 1
        # TODO Log errors?
        print(card_path + " failed")


def _transform_card_json(card_json) -> dict[str, typing.Any]:
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
        "language": "JP",
    }
    for trigger in card_json["trigger"]:
        es_json["triggers"].append({"trigger": trigger})
    for ability in card_json["ability"]:
        es_json["abilities"].append({"ability": ability})
    for specialAttrib in card_json["specialAttrib"]:
        es_json["specialAttribs"].append({"specialAttrib": specialAttrib})

    return es_json


def main():
    es = get_es_client()

    for path in Path(settings.cards_dir).rglob("*.json"):
        _import_card(path, es)

    print(stats)


if __name__ == "__main__":
    main()
