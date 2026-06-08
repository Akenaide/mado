import time
import meilisearch
from meili_client import get_meili_client


def run_benchmark(iterations=1000000):
    start = time.perf_counter()
    for _ in range(iterations):
        client = get_meili_client()
    end = time.perf_counter()

    elapsed = end - start
    print(f"Time for {iterations} iterations: {elapsed:.4f} seconds")
    return elapsed


if __name__ == "__main__":
    run_benchmark()
