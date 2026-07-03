## 2024-05-24 - [Avoid blocking FastAPI event loop with synchronous clients in Strawberry resolvers]
**Learning:** The `meilisearch` Python client is synchronous. In a FastAPI/Strawberry GraphQL setup, returning a synchronous resolver blocking on network calls like `client.index().search()` will block the entire event loop, starving other requests.
**Action:** Always wrap synchronous network or heavy I/O operations inside Strawberry resolvers using `asyncio.to_thread()` and convert the resolver to `async def`. Strawberry natively handles awaiting `async def` resolvers without requiring call site changes.

## 2024-05-24 - [Avoid hidden CPU bottlenecks with dynamic reflection]
**Learning:** Using Python's `dataclasses.fields()` inside a loop or resolver that handles hundreds of results per request incurs unnecessary CPU overhead, as it performs dynamic introspection each time.
**Action:** Compute static sets (e.g., valid dataclass field names) at module load time by hoisting them outside of functions. This prevents O(n) reflection computations on every API request.
