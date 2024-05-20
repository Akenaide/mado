#!/usr/bin/env python3
import fixpath as _
from es_client import get_es_client


def main():
    es = get_es_client()

    print(es.info())


if __name__ == "__main__":
    main()
