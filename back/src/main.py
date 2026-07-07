from config import get_settings
from contextlib import asynccontextmanager
from typing import Union
import typing

import strawberry
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import HTMLResponse
from strawberry.fastapi import GraphQLRouter
from fastapi.staticfiles import StaticFiles

from models import object_set
from models import object_card

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
    cards: typing.List[object_card.Card] = strawberry.field(
        resolver=object_card.get_cards
    )
    search_cards: typing.List[object_card.Card] = strawberry.field(
        resolver=object_card.search_cards
    )
    card: typing.Optional[object_card.Card] = strawberry.field(
        resolver=object_card.get_card
    )
    cards_by_ids: typing.List[object_card.Card] = strawberry.field(
        resolver=object_card.get_cards_by_ids
    )


app = FastAPI(lifespan=lifespan)
app.mount("/medias", StaticFiles(directory=settings.medias_dir), name="medias")
app.add_middleware(GZipMiddleware, minimum_size=1000)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_origin_regex=settings.allow_origin_regex,
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
)

schema = strawberry.Schema(Query)
graphql_app = GraphQLRouter(schema)

app.include_router(graphql_app, prefix="/graphql")


@app.get("/og/set/{set_code}/card/{id_card}", response_class=HTMLResponse)
async def og_card(set_code: str, id_card: str):
    card = await object_card.get_card(id_card)
    if card is None:
        return HTMLResponse(status_code=404, content="Not found")
    image_url = f"{settings.public_url}{card.image_path}"
    description = " · ".join(
        filter(
            None,
            [
                card.name,
                f"Lv.{card.level}" if card.level is not None else None,
                f"Power {card.power}" if card.power else None,
                card.color,
            ],
        )
    )
    html = f"""<!doctype html>
<html>
<head>
  <meta property="og:title" content="{card.name}" />
  <meta property="og:description" content="{description}" />
  <meta property="og:image" content="{image_url}" />
  <meta property="og:type" content="website" />
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="{card.name}" />
  <meta name="twitter:description" content="{description}" />
  <meta name="twitter:image" content="{image_url}" />
</head>
<body></body>
</html>"""
    return HTMLResponse(content=html)


@app.get("/")
def read_root():
    return {"Hello": "World Yayo"}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: Union[str, None] = None):
    return {"item_id": item_id, "q": q}
