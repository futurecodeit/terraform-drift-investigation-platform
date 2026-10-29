import os

from azure.identity import DefaultAzureCredential
from azure.search.documents import SearchClient


def search_standards(query: str, top: int = 3) -> list[dict]:
	endpoint = os.getenv("AI_SEARCH_ENDPOINT")
	index_name = os.getenv("AI_SEARCH_INDEX")
	if not endpoint or not index_name:
		return []

	client = SearchClient(
		endpoint=endpoint,
		index_name=index_name,
		credential=DefaultAzureCredential(),
	)
	results = client.search(
		search_text=query,
		top=top,
		select=["title", "content", "source"],
	)
	return [
		{
			"title": document.get("title"),
			"source": document.get("source"),
			"content": document.get("content"),
		}
		for document in results
	]
