from import_sets import _parse_title_codes, _transform_set_json


def test_parse_title_codes_splits_and_dedupes():
    """
    A hash-delimited TitleName string is parsed into a deduped list of codes.

    Given:
    - raw string "##AB##KW##AB##"

    When:
    - _parse_title_codes(raw) is called

    Then:
    - result == ["AB", "KW"] (order preserved, duplicates removed)
    """
    assert _parse_title_codes("##AB##KW##AB##") == ["AB", "KW"]


def test_parse_title_codes_handles_blank_input():
    """
    A missing/empty TitleName yields an empty list, not an error.

    Given:
    - raw string ""

    When:
    - _parse_title_codes(raw) is called

    Then:
    - result == []
    """
    assert _parse_title_codes("") == []


def test_transform_set_json_includes_title_codes():
    """
    Transforming a set JSON entry resolves its TitleName into title_codes.

    Given:
    - ws_set dict with TitleName="##AB##KW##" plus the other required keys
      (ReleaseDate, SetCode, Title, Image, LicenceCode, ProductType)

    When:
    - _transform_set_json(ws_set) is called

    Then:
    - result.title_codes == ["AB", "KW"]
    """
    ws_set = {
        "ReleaseDate": "2026/05/30",
        "Title": "Angel Beats!／クドわふたー",
        "SetCode": "S130",
        "LicenceCode": "AB",
        "Image": "https://example.com/x.png",
        "ProductType": "ブースターパック",
        "TitleName": "##AB##KW##",
    }
    result = _transform_set_json(ws_set)
    assert result.title_codes == ["AB", "KW"]
