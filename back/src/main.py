from config import get_settings
from contextlib import asynccontextmanager
from typing import Union
import typing

import strawberry
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from strawberry.fastapi import GraphQLRouter
from fastapi.staticfiles import StaticFiles

from models import object_set

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


@strawberry.type
class Query:
    @strawberry.field
    def hello(self) -> str:
        return "Hello World"

    sets: typing.List[object_set.Set] = strawberry.field(resolver=object_set.get_sets)
    search_sets: typing.List[object_set.Set] = strawberry.field(
        resolver=object_set.search_sets
    )


app = FastAPI(lifespan=lifespan)
app.mount("/medias", StaticFiles(directory=settings.medias_dir), name="medias")
# ⚡ Bolt Optimization: Added GZipMiddleware to compress HTTP responses larger than 1000 bytes.
# 🎯 Why: GraphQL responses (JSON) can get quite large. Compressing payloads significantly reduces network transfer times.
# 📊 Impact: Expected to reduce payload sizes for list and search queries by ~70-80%, leading to faster client load times.
app.add_middleware(GZipMiddleware, minimum_size=1000)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

schema = strawberry.Schema(Query)
graphql_app = GraphQLRouter(schema)

app.include_router(graphql_app, prefix="/graphql")


@app.get("/")
def read_root():
    return {"Hello": "World Yayo"}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: Union[str, None] = None):
    return {"item_id": item_id, "q": q}
