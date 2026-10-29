import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "function-app"))

from services.ai_search_client import search_standards

class RagAgent:

    def search(self, question):
        return search_standards(question)