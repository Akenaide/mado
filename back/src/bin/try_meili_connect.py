#!/usr/bin/env python3
import fixpath as _
from meili_client import get_meili_client


def main():
    client = get_meili_client()
    print(client.health())


if __name__ == "__main__":
    main()
