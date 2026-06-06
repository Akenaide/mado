#!/usr/bin/env python3
import fixpath as _

from meili_client import get_meili_client

"""
Configure Meilisearch indexes with searchable and filterable attributes.
"""


def main():
    client = get_meili_client()

    sets = client.index("sets")
    sets.update_searchable_attributes(["title", "release_date"])
    sets.update_filterable_attributes(["set_code", "release_date", "release_year"])

    cards = client.index("cards")
    cards.update_searchable_attributes(["name", "abilities"])
    cards.update_filterable_attributes(
        ["set", "color", "level", "cost", "rarity", "cardType", "language"]
    )

    print("Indexes configured.")


if __name__ == "__main__":
    main()
