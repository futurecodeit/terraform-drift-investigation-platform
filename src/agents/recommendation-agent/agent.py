import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "function-app"))

from services.foundry_client import generate_recommendation

class RecommendationAgent:

    def generate(self, context):
        return generate_recommendation(context)