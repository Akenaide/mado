## 2024-06-20 - Sync Database Calls in Async Resolvers
**Learning:** The `meilisearch` Python client is entirely synchronous. Since the Strawberry GraphQL resolvers are running within a FastAPI/uvicorn async event loop, direct usage of this client blocks the main thread, degrading concurrent request performance severely.
**Action:** Always wrap synchronous client calls (like those from the `meilisearch` Python client) in `await asyncio.to_thread(...)` when writing `async def` resolvers in Strawberry/FastAPI.
