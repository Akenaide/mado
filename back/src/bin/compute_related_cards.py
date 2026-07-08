#!/usr/bin/env python3
from collections import defaultdict

import fixpath as _  # noqa: F401
from meili_client import get_meili_client


def _build_related_map(cards):
    name_to_ids = defaultdict(list)
    for c in cards:
        name_to_ids[c["name"]].append(c["id_card"])

    related = defaultdict(set)
    for card in cards:
        text = " ".join(card.get("abilities", []))
        for name, ids in name_to_ids.items():
            if name and name in text:
                for rid in ids:
                    if rid != card["id_card"]:
                        related[card["id_card"]].add(rid)
                        related[rid].add(card["id_card"])
    return related


def _fetch_set_cards(index, set_code):
    offset, batch = 0, 1000
    cards = []
    while True:
        result = index.search(
            "",
            {
                "filter": f'set = "{set_code}"',
                "limit": batch,
                "offset": offset,
                "attributesToRetrieve": ["id_card", "name", "abilities"],
            },
        )
        hits = result["hits"]
        cards.extend(hits)
        if len(hits) < batch:
            break
        offset += batch
    return cards


def _fetch_all_licence_codes(sets_index):
    result = sets_index.search(
        "", {"limit": 1000, "attributesToRetrieve": ["licence_code"]}
    )
    return list({h["licence_code"] for h in result["hits"] if h.get("licence_code")})


def main():
    client = get_meili_client()
    cards_index = client.index("cards")
    licence_codes = _fetch_all_licence_codes(client.index("sets"))
    for set_code in licence_codes:
        cards = _fetch_set_cards(cards_index, set_code)
        related_map = _build_related_map(cards)
        updates = [
            {"id_card": k, "related_cards": list(v)} for k, v in related_map.items()
        ]
        if updates:
            task = cards_index.update_documents(updates, primary_key="id_card")
            client.wait_for_task(task.task_uid)
            print(f"{set_code}: {len(updates)} cards updated")
    print("Done")


if __name__ == "__main__":
    main()
