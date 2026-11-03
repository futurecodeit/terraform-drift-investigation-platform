import os

from azure.search.documents import SearchClient

from common.auth import credential


def search_knowledge(query: str) -> list[dict]:
    client = SearchClient(
        endpoint=os.environ["SEARCH_ENDPOINT"],
        index_name=os.environ["SEARCH_INDEX"],
        credential=credential,
    )
    results = client.search(search_text=query, top=5)
    return [dict(result) for result in results]
