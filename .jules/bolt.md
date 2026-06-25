## 2024-06-25 - Asyncio and synchronous Meilisearch client
**Learning:** Meilisearch's python client is completely synchronous. While FastAPI + Strawberry works mostly natively async, these sync network requests stall the Uvicorn event loop significantly.
**Action:** When working with FastAPI + Meilisearch in this repository, always wrap `client.index().search()` calls inside `asyncio.to_thread()` within `async def` strawberry resolvers to prevent blocking concurrent GraphQL requests.
