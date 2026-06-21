## 2024-06-21 - Asynchronous resolvers for meilisearch network calls
**Learning:** The Python client for `meilisearch` is synchronous. Making network requests to it inside an `async` FastAPI/Strawberry GraphQL resolver blocks the main uvicorn event loop. This creates a severe concurrency bottleneck where one request can block the entire backend.
**Action:** Always wrap synchronous meilisearch client network calls with `asyncio.to_thread()` inside `async def` resolvers to offload the I/O blocking operation to a thread pool and prevent blocking the event loop.
