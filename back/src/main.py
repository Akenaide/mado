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
    set_stats: object_set.SetStats = strawberry.field(resolver=object_set.get_set_stats)


app = FastAPI(lifespan=lifespan)
app.mount("/medias", StaticFiles(directory=settings.medias_dir), name="medias")
app.add_middleware(GZipMiddleware, minimum_size=1000)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
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
