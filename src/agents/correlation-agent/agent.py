class CorrelationAgent:

    def correlate(
            self,
            drift,
            activity,
            change,
            identity,
            rag=None):
        return {
            "resource": drift.get("address"),
            "resource_id": drift.get("resource_id"),
            "changes": drift.get("changes", []),
            "activity": activity or [],
            "identity": identity or {"user": "unknown", "verification": "not available"},
            "knowledge_evidence": rag or [],
        }