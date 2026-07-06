_GQL_CARDS = '{ cards(setCode: "BCS/W52") { idCard name setCode } }'
_GQL_CARDS_SORT = '{ cards(setCode: "BCS/W52") { idCard } }'
_GQL_CARDS_PAGINATED = (
    '{ cards(setCode: "BCS/W52", pageNum: 2, pageSize: 10) { idCard } }'
)

_CARD_HIT = {
    "set_code": "BCS/W52",
    "name": "Test Card",
    "image64": "",
    "image_url": "",
    "id_card": "BCS/W52-001",
    "ability": [],
    "rarity": "C",
    "level": 0,
    "cost": 0,
    "power": 500,
    "soul": 1,
    "color": "Y",
    "card_type": "Character",
    "special_attribute": [],
    "language": "jp",
    "cardcode": "dummy",
    "set": "dummy",
    "set_name": "dummy",
    "side": "dummy",
    "release": "dummy",
    "image_path": "dummy",
    "abilities": [],
    "triggers": [],
    "flavour_text": "dummy",
    "expansionId": 1,
}


def test_cards_returns_cards_for_set_code(client, mock_meili_cards):
    """
    cards(setCode) returns cards belonging to that set.

    Given:
    - Meilisearch `cards` index returns two hits when filtered by set_code="BCS/W52"

    When:
    - GraphQL query `{ cards(setCode: "BCS/W52") { idCard name setCode } }` is sent

    Then:
    - Response contains exactly 2 cards
    - Each card has setCode == "BCS/W52"
    """
    mock_meili_cards.index.return_value.search.return_value = {
        "hits": [_CARD_HIT, {**_CARD_HIT, "id_card": "BCS/W52-002"}],
    }

    response = client.post("/graphql", json={"query": _GQL_CARDS})
    assert response.status_code == 200
    data = response.json()

    assert "errors" not in data, data.get("errors")
    cards = data["data"]["cards"]
    assert len(cards) == 2
    assert all(c["setCode"] == "BCS/W52" for c in cards)


def test_cards_ordered_by_id_card(client, mock_meili_cards):
    """
    cards(setCode) passes sort=["id_card:asc"] to Meilisearch.

    Given:
    - Meilisearch cards index is mocked

    When:
    - GraphQL query `{ cards(setCode: "BCS/W52") { idCard } }` is sent

    Then:
    - Meilisearch search was called with sort=["id_card:asc"] in the options
    """
    mock_meili_cards.index.return_value.search.return_value = {"hits": []}

    response = client.post("/graphql", json={"query": _GQL_CARDS_SORT})
    assert response.status_code == 200

    options = mock_meili_cards.index.return_value.search.call_args[0][1]
    assert options.get("sort") == ["id_card:asc"]


def test_cards_pagination(client, mock_meili_cards):
    """
    cards(setCode, pageNum, pageSize) forwards pagination params to Meilisearch.

    Given:
    - Meilisearch cards index is mocked

    When:
    - `{ cards(setCode: "BCS/W52", pageNum: 2, pageSize: 10) { idCard } }` is sent

    Then:
    - Meilisearch search was called with offset=10, limit=10
    """
    mock_meili_cards.index.return_value.search.return_value = {"hits": []}

    response = client.post("/graphql", json={"query": _GQL_CARDS_PAGINATED})
    assert response.status_code == 200

    options = mock_meili_cards.index.return_value.search.call_args[0][1]
    assert options.get("offset") == 10
    assert options.get("limit") == 10
