## 2024-07-02 - Meilisearch Sync Client Blocking Event Loop
**Learning:** The official `meilisearch` Python client is synchronous. In a FastAPI/Strawberry application, using it directly inside `def` resolvers blocks the main event loop, severely degrading concurrent request handling.
**Action:** Always wrap Meilisearch network calls with `asyncio.to_thread()` inside `async def` resolvers to offload the I/O to a thread pool and keep the event loop non-blocking.
