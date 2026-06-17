## 2024-06-17 - ThreadPoolExecutor for Meilisearch GraphQL Resolvers
**Learning:** In a FastAPI/Strawberry backend running on uvicorn, synchronous external I/O (like Meilisearch searches) in standard `def` resolvers blocks the ASGI event loop, limiting concurrent requests processing.
**Action:** Always wrap synchronous blocking calls in `async def` resolvers using `asyncio.to_thread()` to offload the I/O to a thread pool and prevent blocking the main event loop, significantly improving backend concurrency under load.
