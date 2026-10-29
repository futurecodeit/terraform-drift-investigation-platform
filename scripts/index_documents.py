import hashlib
import os
import sys
from pathlib import Path

from azure.identity import DefaultAzureCredential
from azure.search.documents import SearchClient
from azure.search.documents.indexes import SearchIndexClient
from azure.search.documents.indexes.models import (
	SearchFieldDataType,
	SearchIndex,
	SearchableField,
	SimpleField,
)


def main() -> None:
	endpoint = os.environ.get("AI_SEARCH_ENDPOINT")
	index_name = os.environ.get("AI_SEARCH_INDEX", "platform-knowledge")
	if not endpoint:
		raise SystemExit("Set AI_SEARCH_ENDPOINT to the Azure AI Search service endpoint.")

	source_root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("knowledge")
	files = sorted(
		path for path in source_root.rglob("*")
		if path.is_file() and path.suffix.lower() in {".md", ".txt"}
	)
	if not files:
		raise SystemExit(f"No Markdown or text documents found under {source_root}.")

	credential = DefaultAzureCredential()
	index_client = SearchIndexClient(endpoint, credential)
	index_client.create_or_update_index(
		SearchIndex(
			name=index_name,
			fields=[
				SimpleField(
					name="id",
					type=SearchFieldDataType.String,
					key=True,
					filterable=True,
				),
				SearchableField(name="title", type=SearchFieldDataType.String),
				SearchableField(name="content", type=SearchFieldDataType.String),
				SimpleField(name="source", type=SearchFieldDataType.String, filterable=True),
			],
		)
	)

	documents = []
	for path in files:
		content = path.read_text(encoding="utf-8").strip()
		if not content:
			continue
		source = path.relative_to(source_root).as_posix()
		documents.append(
			{
				"id": hashlib.sha256(source.encode("utf-8")).hexdigest(),
				"title": path.stem.replace("-", " ").replace("_", " "),
				"content": content,
				"source": source,
			}
		)

	if not documents:
		raise SystemExit("The selected documents are empty.")

	search_client = SearchClient(endpoint, index_name, credential)
	result = search_client.upload_documents(documents)
	failures = [item for item in result if not item.succeeded]
	if failures:
		raise RuntimeError(f"Azure AI Search rejected {len(failures)} document(s).")
	print(f"Indexed {len(documents)} document(s) into '{index_name}'.")


if __name__ == "__main__":
	main()
