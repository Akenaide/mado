from contextlib import asynccontextmanager
import os
from typing import Union

from fastapi import FastAPI

from es_client import create_es_api_key
from es_client import API_KEY_PATH


@asynccontextmanager
async def lifespan(app: FastAPI):
    # check if ES API key exists
    if not os.path.exists(API_KEY_PATH):
        create_es_api_key()

    yield


app = FastAPI(lifespan=lifespan)


@app.get("/")
def read_root():
    return {"Hello": "World Yayo"}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: Union[str, None] = None):
    return {"item_id": item_id, "q": q}
