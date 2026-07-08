## 2024-07-08 - [Dataclass Fields Precomputation]
**Learning:** Calling `dataclasses.fields()` on a dataclass (like `Card`) inside a high-frequency loop (such as inside a GraphQL resolver filtering thousands of hits) causes unnecessary dynamic lookup overhead, leading to hidden CPU bottlenecks.
**Action:** Always precompute `dataclasses.fields()` at the module level (e.g., `_CARD_FIELDS = frozenset(f.name for f in dataclasses.fields(Card))`) instead of dynamically recalculating it within request loops.

## 2024-07-08 - [Strawberry Async Resolvers]
**Learning:** When converting a synchronous Strawberry GraphQL resolver to an async function (to prevent blocking the FastAPI/uvicorn event loop with a synchronous client like `meilisearch`), no call site updates are needed for `strawberry.field(resolver=...)` registrations, as Strawberry natively identifies and awaits the coroutines automatically. However, we must ensure other non-GraphQL synchronous callers in the application (like standard FastAPI routes) are updated to correctly `await` the newly async function.
**Action:** Ensure all callers of modified GraphQL resolvers are thoroughly checked and updated if converted to async.
