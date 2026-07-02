## 2024-05-24 - [Avoid Event Loop Blocking & Expensive Recomputation in Resolvers]
**Learning:** Synchronous Meilisearch calls inside a synchronous Strawberry GraphQL resolver block the entire FastAPI event loop. Additionally, `dataclasses.fields()` called inside the request loop creates a hidden CPU bottleneck on every query (found when comparing benchmark: 0.38s vs 0.004s per 100k calls).
**Action:** Always wrap synchronous IO in `asyncio.to_thread()` within an `async def` resolver, and compute constant sets like dataclass fields once at module load time.
