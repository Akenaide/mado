#!/usr/bin/env python3
import asyncio
import dataclasses
import datetime
import hashlib
import json
import logging
import os
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
    "updated": 0,
    "failed": 0,
}

IMAGES_DIR = Path(settings.medias_dir) / "sets_images"


@dataclass()
class Document:
    id: str
    release_date: str
    release_year: int
    title: str
    image_url: str
    set_code: str
    licence_code: str
    product_type: str


def _transform_set_json(ws_set) -> Document:
    """
    Transform a wsoffcli-format JSON set to our Meilisearch format
    """
    parsed_date = datetime.datetime.strptime(ws_set["ReleaseDate"], "%Y/%m/%d").date()
    set_code = ws_set["SetCode"]
    title = ws_set["Title"]
    release_date = parsed_date.isoformat()
    product_type = ws_set["ProductType"]

    return Document(
        id=hashlib.sha1(
            f"{set_code}|{product_type}|{title}|{release_date}".encode()
        ).hexdigest(),
        release_date=release_date,
        release_year=parsed_date.year,
        title=title,
        image_url=ws_set["Image"],
        set_code=set_code,
        licence_code=ws_set.get("LicenceCode", ""),
        product_type=ws_set.get("ProductType", ""),
    )


async def _download_image(
    client: httpx.AsyncClient,
    doc: Document,
) -> dict:
    url = doc.image_url
    ext = Path(urlparse(url).path).suffix or ".jpg"
    dest = IMAGES_DIR / f"{doc.id}{ext}"
    result = dataclasses.asdict(doc)

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
    index = client.index("sets")
    docs = []

    with open(settings.set_file) as json_file:
        sets = json.load(json_file)

    IMAGES_DIR.mkdir(parents=True, exist_ok=True)

    for _set in sets:
        if _set["SetCode"]:
            docs.append(_transform_set_json(_set))

    docs = asyncio.run(_download_all_images(docs))

    task = index.add_documents(docs)
    result = client.wait_for_task(task.task_uid)
    print(result)
    stats["created"] = len(docs)
    print(f"Indexed {len(docs)} sets")
    print(stats)


if __name__ == "__main__":
    main()
