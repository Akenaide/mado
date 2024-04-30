from contextlib import asynccontextmanager
import os
from typing import Union
import typing

import strawberry
from fastapi import FastAPI
from strawberry.fastapi import GraphQLRouter

from es_client import create_es_api_key
from es_client import API_KEY_PATH
from models import object_set


@asynccontextmanager
async def lifespan(app: FastAPI):
    # check if ES API key exists
    if not os.path.exists(API_KEY_PATH):
        create_es_api_key()

    yield


@strawberry.type
class Query:
    @strawberry.field
    def hello(self) -> str:
        return "Hello World"

    sets: typing.List[object_set.Set] = strawberry.field(resolver=object_set.get_sets)


app = FastAPI(lifespan=lifespan)

schema = strawberry.Schema(Query)
graphql_app = GraphQLRouter(schema)

app.include_router(graphql_app, prefix="/graphql")


@app.get("/")
def read_root():
    return {"Hello": "World Yayo"}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: Union[str, None] = None):
    return {"item_id": item_id, "q": q}
