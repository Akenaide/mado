## 2024-06-25 - Async wrappers for Synchronous SDKs in Event-Loop Frameworks
**Learning:** Using synchronous clients (like the default Python Meilisearch client) directly inside Strawberry GraphQL resolvers running on FastAPI blocks the uvicorn event loop, severely degrading performance and concurrency under load.
**Action:** Always wrap synchronous blocking network or I/O calls with `asyncio.to_thread()` within `async def` functions in event-loop-driven frameworks to offload work to a thread pool and preserve the main thread's responsiveness.
