import pytest

from compute_related_cards import _build_related_map


def _card(id_card, name, abilities=None):
    return {"id_card": id_card, "name": name, "abilities": abilities or []}


def test_name_in_abilities_creates_mutual_relation():
    """
    Card whose name appears in another card's abilities becomes mutually related.

    Given:
    - card_a: id_card="SET-001", name="Alice", abilities=["bond with Bob"]
    - card_b: id_card="SET-002", name="Bob", abilities=[]

    When:
    - _build_related_map([card_a, card_b]) is called

    Then:
    - "SET-002" in related_map["SET-001"]
    - "SET-001" in related_map["SET-002"]
    """
    cards = [
        _card("SET-001", "Alice", ["bond with Bob"]),
        _card("SET-002", "Bob"),
    ]
    result = _build_related_map(cards)
    assert "SET-002" in result["SET-001"]
    assert "SET-001" in result["SET-002"]


def test_foils_with_same_name_are_not_related():
    """
    Two cards sharing the same name (foils) are not related if neither's abilities mention the other.

    Given:
    - card_normal: id_card="SET-001",  name="Alice", abilities=[]
    - card_foil:   id_card="SET-001S", name="Alice", abilities=[]

    When:
    - _build_related_map([card_normal, card_foil]) is called

    Then:
    - "SET-001S" NOT in related_map["SET-001"]
    - "SET-001"  NOT in related_map["SET-001S"]
    """
    cards = [
        _card("SET-001", "Alice"),
        _card("SET-001S", "Alice"),
    ]
    result = _build_related_map(cards)
    assert "SET-001S" not in result.get("SET-001", set())
    assert "SET-001" not in result.get("SET-001S", set())


def test_card_not_related_to_itself():
    """
    A card whose own name appears in its abilities is not in its own related_cards.

    Given:
    - card: id_card="SET-001", name="Alice", abilities=["Alice's power"]

    When:
    - _build_related_map([card]) is called

    Then:
    - "SET-001" NOT in related_map["SET-001"]
    """
    cards = [_card("SET-001", "Alice", ["Alice's power"])]
    result = _build_related_map(cards)
    assert "SET-001" not in result.get("SET-001", set())
