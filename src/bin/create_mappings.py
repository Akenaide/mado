#!/usr/bin/env python3
import json
import os

import fixpath as _
from es_client import get_es_client

"""
Create ES mappings for cards
"""

def main():
    es = get_es_client()

    with open(os.path.join(os.path.dirname(__file__), 'cards_mappings.json'), "r", encoding='utf-8') as json_file:
        mappings = json.load(json_file)
        es.indices.create(index="cards", mappings=mappings)


if __name__ == "__main__":
    main()
