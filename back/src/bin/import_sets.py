#!/usr/bin/env python3
import datetime
import typing
import json
import logging

import fixpath as _
from config import get_settings
from es_client import get_es_client

if typing.TYPE_CHECKING:
    import elasticsearch

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


def _import_set(ws_set: str, client: "elasticsearch.Elasticsearch") -> None:
    """
    Import a single .json card
    """
    es_json = _transform_set_json(ws_set)
    if client.exists(index=settings.set_index, id=es_json["title"]):
        logger.info("Set '%s' already exists", es_json["title"])
        return
    resp = client.index(index=settings.set_index, body=es_json, id=es_json["title"])

    if resp["result"] in ["created", "updated"]:
        stats[resp["result"]] += 1
    else:
        stats["failed"] += 1
        # TODO Log errors?
        print(ws_set + " failed")


def _transform_set_json(ws_set) -> dict[str, typing.Any]:
    """
    Transform a wsoffcli-format JSON card to our ES format
    Arrays need to be separated this way to allow full-text search
    """

    # Parse ReleaseDate in iso format
    release_date = (
        datetime.datetime.strptime(ws_set["ReleaseDate"], "%Y/%m/%d").date().isoformat()
    )

    # Update the dictionary with the parsed date
    es_json = {
        "release_date": release_date,
        "title": ws_set["Title"],
        "image_url": ws_set["Image"],
        "set_code": ws_set["SetCode"],
    }

    return es_json


def main():
    es = get_es_client()

    with open(settings.set_file) as json_file:
        sets = json.load(json_file)
    for _set in sets:
        _import_set(_set, client=es)

    print(stats)


if __name__ == "__main__":
    main()
