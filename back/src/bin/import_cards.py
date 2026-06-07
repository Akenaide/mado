#!/usr/bin/env python3
import asyncio
import dataclasses
import json
import logging
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urlparse

import httpx

import fixpath as _
from config import get_settings
from meili_client import get_meili_client

logger = logging.getLogger(__name__)
"""
Recursively import all .json files from the cards directory
"""

settings = get_settings()
stats = {
    "created": 0,
    "failed": 0,
}

IMAGES_DIR = Path(settings.medias_dir) / "cards_images"


@dataclass
class Document:
    id: str
    cardcode: str
    set: str
    set_name: str
    side: str
    release: str
    name: str
    image_url: str
    card_type: str
    color: str
    level: str
    cost: str
    power: str
    soul: str
    rarity: str
    triggers: list
    abilities: list
    special_attribs: list
    flavour_text: str
    expansionId: int
    language: str


def _transform_card_json(card_json) -> Document:
    return Document(
        id=card_json["cardcode"].split("/")[1],
        cardcode=card_json["cardcode"],
        set=card_json["set"],
        set_name=card_json["setName"],
        side=card_json.get("side", ""),
        release=card_json.get("release", ""),
        name=card_json.get("jpName") or card_json.get("name", ""),
        image_url=card_json.get("imageURL", ""),
        card_type=card_json["cardType"],
        color=card_json["colour"],
        level=card_json["level"],
        cost=card_json["cost"],
        power=card_json["power"],
        soul=card_json["soul"],
        rarity=card_json["rarity"],
        triggers=card_json["trigger"] or [],
        abilities=card_json.get("ability") or [],
        special_attribs=card_json.get("specialAttrib") or [],
        flavour_text=card_json.get("flavourText", ""),
        expansionId=card_json["expansionId"],
        language="JP",
    )


async def _download_image(client: httpx.AsyncClient, doc: Document) -> dict:
    url = doc.image_url
    print(url)
    result = dataclasses.asdict(doc)

    if not url:
        return result

    ext = Path(urlparse(url).path).suffix or ".jpg"
    dest = IMAGES_DIR / f"{doc.id.replace('/', '_')}{ext}"

    if dest.exists():
        return {**result, "image_path": str(dest)}

    try:
        response = await client.get(url)
        response.raise_for_status()
        dest.write_bytes(response.content)
        return {**result, "image_path": str(dest)}
    except Exception as exc:
        logger.warning("Failed to download %s: %s", url, exc)
        stats["failed"] += 1
        return result


async def _download_all_images(docs: list[Document]) -> list[dict]:
    async with httpx.AsyncClient(timeout=30) as client:
        return await asyncio.gather(*[_download_image(client, doc) for doc in docs])


def main():
    client = get_meili_client()
    index = client.index("cards")

    raw_docs = []
    for path in Path(settings.cards_dir).rglob("*.json"):
        print(path)
        with open(path, "r", encoding="utf-8") as json_file:
            card_json = json.load(json_file)
        raw_docs.append(_transform_card_json(card_json))

    IMAGES_DIR.mkdir(parents=True, exist_ok=True)
    docs = asyncio.run(_download_all_images(raw_docs))

    task = index.add_documents(docs, primary_key="id")
    result = client.wait_for_task(task.task_uid)
    print(result)
    stats["created"] = len(docs)
    print(f"Indexed {len(docs)} cards")
    print(stats)


if __name__ == "__main__":
    main()
