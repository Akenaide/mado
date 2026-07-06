## 2025-02-28 - Meilisearch Client Sync Blocking

**Learning:** The meilisearch Python client is synchronous and blocks the FastAPI/uvicorn event loop when used directly inside a synchronous Strawberry GraphQL resolver. Additionally, using `dataclasses.fields()` inside a request loop causes a hidden CPU bottleneck.

**Action:** Wrap synchronous meilisearch client calls in `asyncio.to_thread` within `async def` Strawberry GraphQL resolvers. Cache constant operations like `dataclasses.fields()` at the module level rather than recomputing them per request.
