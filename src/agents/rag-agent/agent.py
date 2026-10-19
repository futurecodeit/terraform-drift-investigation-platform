from azure.search.documents import SearchClient
from azure.identity import ManagedIdentityCredential

class RagAgent:

    def __init__(
            self,
            endpoint,
            index_name):

        self.client = SearchClient(
            endpoint=endpoint,
            index_name=index_name,
            credential=ManagedIdentityCredential()
        )

    def search(self, question):

        results = self.client.search(question)

        response = []

        for doc in results:
            response.append(doc)

        return response