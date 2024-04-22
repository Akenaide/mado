from es_import import utilities

# TODO
def parse_sets(sets_dir: str, client: utilities.ESClient) -> None:
    print("Parse sets")
    sets_json = utilities.get_json(sets_dir)
