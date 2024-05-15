#!/usr/bin/env python3
import fixpath as _
from es_client import get_es_client
from models.object_card import es_mappings

"""
Create ES mappings for cards
"""

def main():
    es = get_es_client()
    es.indices.create(index="cards", mappings=es_mappings)


if __name__ == "__main__":
    main()
