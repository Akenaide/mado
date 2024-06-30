#!/usr/bin/env python3
import fixpath as _

from config import get_settings
from es_client import get_es_client
from models.object_card import card_es_mappings
from models.object_set import set_es_mappings

settings = get_settings()
"""
Create ES mappings for cards
"""


def main():
    es = get_es_client()
    es.indices.create(index=settings.card_index, mappings=card_es_mappings)
    es.indices.create(index=settings.set_index, mappings=set_es_mappings)


if __name__ == "__main__":
    main()
