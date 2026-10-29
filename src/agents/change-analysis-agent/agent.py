class ChangeAnalysisAgent:
    def get_changes(self, drift):
        return drift.get("changes", [])
