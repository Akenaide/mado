## 2023-10-24 - Async Meilisearch Queries in FastAPI
**Learning:** Meilisearch's Python client uses synchronous HTTP requests (via `requests`) under the hood. When used in FastAPI resolvers, these synchronous calls block the main event loop, severely limiting concurrency and performance.
**Action:** Always wrap synchronous Meilisearch calls (or any network I/O that doesn't have an async implementation) using `asyncio.to_thread` and make the strawberry resolvers `async` to offload the I/O to a background thread and keep the event loop non-blocking.
