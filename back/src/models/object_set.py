import strawberry


@strawberry.type
class Set:
    release_date: str
    title: str
    image64: str
    image_url: str
    set_code: str
