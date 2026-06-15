_GQL_SET_STATS = "{ setStats { total byProductType { name count } } }"

_GQL_SET_STATS_FILTERED = (
    '{ setStats(query: "sword") { total byProductType { name count } } }'
)


def test_set_stats_returns_total_and_categories(client, mock_meili):
    """
    setStats returns total count and per-category breakdown.

    Given:
    - Meilisearch `sets` index returns facetDistribution:
      {"product_type": {"ブースターパック": 80, "トライアルデッキ": 30}}

    When:
    - GraphQL query `{ setStats { total byProductType { name count } } }` is sent

    Then:
    - total == 110
    - byProductType has two entries with correct counts
    """
    mock_meili.index.return_value.search.return_value = {
        "hits": [],
        "facetDistribution": {
            "product_type": {"ブースターパック": 80, "トライアルデッキ": 30}
        },
    }

    response = client.post("/graphql", json={"query": _GQL_SET_STATS})
    assert response.status_code == 200
    data = response.json()

    assert "errors" not in data, data.get("errors")
    stats = data["data"]["setStats"]
    assert stats["total"] == 110
    by_type = {item["name"]: item["count"] for item in stats["byProductType"]}
    assert by_type["ブースターパック"] == 80
    assert by_type["トライアルデッキ"] == 30


def test_set_stats_filtered_by_query(client, mock_meili):
    """
    setStats forwards the query string to Meilisearch, returning filtered stats.

    Given:
    - Meilisearch returns a narrower facetDistribution when query="sword":
      {"product_type": {"ブースターパック": 5}}

    When:
    - `{ setStats(query: "sword") { total byProductType { name count } } }` is sent

    Then:
    - Meilisearch was called with query="sword"
    - total == 5
    - byProductType has one entry
    """
    mock_meili.index.return_value.search.return_value = {
        "hits": [],
        "facetDistribution": {"product_type": {"ブースターパック": 5}},
    }

    response = client.post("/graphql", json={"query": _GQL_SET_STATS_FILTERED})
    assert response.status_code == 200
    data = response.json()

    assert "errors" not in data, data.get("errors")
    stats = data["data"]["setStats"]
    assert stats["total"] == 5
    assert len(stats["byProductType"]) == 1

    mock_meili.index.return_value.search.assert_called_once_with(
        "sword", {"limit": 0, "facets": ["product_type"]}
    )
