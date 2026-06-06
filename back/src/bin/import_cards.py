#!/usr/bin/env python3
import json
from pathlib import Path
import typing

import fixpath as _
from config import get_settings
from meili_client import get_meili_client

"""
Recursively import all .json files from the cards directory
"""

settings = get_settings()


def _transform_card_json(card_json) -> dict[str, typing.Any]:
    """
    Transform a wsoffcli-format JSON card to our Meilisearch format
    """
    return {
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
        "triggers": [t for t in card_json["trigger"]],
        "abilities": card_json["ability"],
        "specialAttribs": card_json["specialAttrib"],
        "language": "JP",
    }


def main():
    client = get_meili_client()
    index = client.index("cards")

    docs = []
    for path in Path(settings.cards_dir).rglob("*.json"):
        with open(path, "r", encoding="utf-8") as json_file:
            card_json = json.load(json_file)
        docs.append(_transform_card_json(card_json))

    task = index.add_documents(docs, primary_key="id")
    print(f"Enqueued {len(docs)} cards (task uid: {task.task_uid})")


if __name__ == "__main__":
    main()
