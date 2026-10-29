import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "function-app"))

from drift import analyze_plan

class TerraformAnalyzerAgent:

    def analyze(self, tfplan_json):
        return analyze_plan(tfplan_json)["drifts"]