## 2024-06-26 - [Async resolvers for synchronous meilisearch client]
**Learning:** Meilisearch synchronous calls in this architecture will block the event loop unless wrapped in `asyncio.to_thread()`.
**Action:** Always wrap synchronous meilisearch network calls in `asyncio.to_thread()` inside `async def` Strawberry resolvers.
