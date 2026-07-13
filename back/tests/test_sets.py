_GQL_SEARCH_SETS = '{ searchSets(query: "AB") { setCode titleCodes } }'


def test_search_sets_returns_title_codes(client, mock_meili):
    """
    searchSets exposes titleCodes so the frontend can search/display by title code.

    Given:
    - Meilisearch `sets` index search returns one hit with title_codes: ["AB", "KW"]

    When:
    - GraphQL query `{ searchSets(query: "AB") { setCode titleCodes } }` is sent

    Then:
    - response has no errors
    - searchSets[0].titleCodes == ["AB", "KW"]
    """
    mock_meili.index.return_value.search.return_value = {
        "hits": [
            {
                "id": "abc123",
                "release_date": "2026-05-30",
                "release_year": 2026,
                "title": "Angel Beats!／クドわふたー",
                "set_code": "S130",
                "title_codes": ["AB", "KW"],
            }
        ]
    }
    response = client.post("/graphql", json={"query": _GQL_SEARCH_SETS})
    assert response.status_code == 200
    data = response.json()
    assert "errors" not in data, data.get("errors")
    assert data["data"]["searchSets"][0]["titleCodes"] == ["AB", "KW"]
