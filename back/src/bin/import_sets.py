#!/usr/bin/env python3
import datetime
import typing
import json
import logging

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


def main():
    client = get_meili_client()
    index = client.index("sets")

    with open(settings.set_file) as json_file:
        sets = json.load(json_file)

    docs = [_transform_set_json(s) for s in sets if s["SetCode"]]
    task = index.add_documents(docs, primary_key="set_code")
    result = client.wait_for_task(task.task_uid)
    print(result)
    stats["created"] = len(docs)
    print(f"Indexed {len(docs)} sets")
    print(stats)


if __name__ == "__main__":
    main()
