## 2024-05-24 - Async IO in Strawberry GraphQL Resolvers
**Learning:** The `meilisearch` Python client is completely synchronous. Using it directly inside a FastAPI/Strawberry resolver blocks the main uvicorn event loop, causing severe latency degradation under concurrent load. Strawberry seamlessly handles `async def` resolvers without requiring call site updates.
**Action:** When creating new resolvers or database queries using synchronous clients in this backend, always define the resolver as `async def` and wrap network calls inside `asyncio.to_thread()`.
