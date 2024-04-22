import os

from es_import import utilities

def create_mappings(client: utilities.ESClient) -> None:
    """
    Create ES mappings for cards
    """
    mappings = utilities.get_json(os.path.join(os.path.dirname(__file__), 'cards_mappings.json'))
    client.get_client.indices.create(index="cards", mappings=mappings)