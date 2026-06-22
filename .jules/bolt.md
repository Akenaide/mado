## 2024-06-22 - Optimize Meilisearch Client Sync Calls in GraphQL Resolvers
**Learning:** The Python Meilisearch client is synchronous. In a FastAPI/uvicorn application using Strawberry GraphQL, making synchronous network calls within a resolver blocks the event loop, causing poor concurrency and performance bottlenecks.
**Action:** Always wrap synchronous Meilisearch `client.index().search()` calls using `asyncio.to_thread()` within an `async def` Strawberry resolver to allow the event loop to handle other concurrent requests.
