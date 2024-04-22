#!/usr/bin/python3

import argparse
import sys

from es_import import cards, sets, mappings
from es_import.env_file import EnvFile
from es_import.utilities import ESClient

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cert", required=True, help="HTTPS certificate path", action="store")
    parser.add_argument("--env", required=True, help=".env file path", action="store")
    parser.add_argument("--endpoint", default="https://localhost:9200", help="ElasticSearch server endpoint", action="store")
    parser.add_argument("-c", "--cards", help="import card data", action="store")
    parser.add_argument("-s", "--sets", help="import set data", action="store")
    parser.add_argument("-m", "--mappings", help="create mappings index", action="store_true")
    args = parser.parse_args()

    # Parse .env file
    env_file = EnvFile(args.env)

    # Setup ES client
    client = ESClient(
        cert_path=args.cert,
        env_file=env_file, 
        endpoint=args.endpoint)

    if args.cards:
        cards.import_cards(cards_dir=args.cards, client=client)
    elif args.sets:
        sets.parse_sets(sets_dir=args.sets, client=client)
    elif args.mappings:
        mappings.create_mappings(client=client)
    else:
        parser.print_help()
    return 0

if __name__ == '__main__':
    sys.exit(main())