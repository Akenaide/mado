#!/usr/bin/env python3
import asyncio
import datetime
import json
import logging
import os
import typing
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


def _transform_set_json(ws_set) -> dict[str, typing.Any]:
    """
    Transform a wsoffcli-format JSON set to our Meilisearch format
    """
    parsed_date = datetime.datetime.strptime(ws_set["ReleaseDate"], "%Y/%m/%d").date()

    return {
        "release_date": parsed_date.isoformat(),
        "release_year": parsed_date.year,
        "title": ws_set["Title"],
        "image_url": ws_set["Image"],
        "set_code": ws_set["SetCode"],
    }


async def _download_image(
    client: httpx.AsyncClient, doc: dict, medias_dir: Path
) -> dict:
    url = doc["image_url"]
    ext = Path(urlparse(url).path).suffix or ".jpg"
    dest = medias_dir / f"{doc['set_code']}{ext}"

    if dest.exists():
        return {**doc, "image_path": str(dest)}

    try:
        response = await client.get(url)
        response.raise_for_status()
        dest.write_bytes(response.content)
        return {**doc, "image_path": str(dest)}
    except Exception as exc:
        logger.warning("Failed to download %s: %s", url, exc)
        stats["failed"] += 1
        return doc


async def _download_all_images(docs: list[dict], medias_dir: Path) -> list[dict]:
    async with httpx.AsyncClient(timeout=30) as client:
        return await asyncio.gather(
            *[_download_image(client, doc, medias_dir) for doc in docs]
        )


def main():
    client = get_meili_client()
    index = client.index("sets")
    docs = []

    with open(settings.set_file) as json_file:
        sets = json.load(json_file)

    medias_dir = Path(settings.medias_dir)
    medias_dir.mkdir(parents=True, exist_ok=True)

    for _set in sets:
        if _set["SetCode"]:
            docs.append(_transform_set_json(_set))

    docs = asyncio.run(_download_all_images(docs, medias_dir))

    task = index.add_documents(docs, primary_key="set_code")
    result = client.wait_for_task(task.task_uid)
    print(result)
    stats["created"] = len(docs)
    print(f"Indexed {len(docs)} sets")
    print(stats)


if __name__ == "__main__":
    main()
