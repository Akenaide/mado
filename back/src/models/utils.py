def pagination(page_size: int, page_num: int) -> dict[str, int]:

    offset = (page_num - 1) * page_size
    return {"offset": offset, "limit": page_size}
