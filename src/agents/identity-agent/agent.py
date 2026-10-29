class IdentityAgent:

    def get_identity_details(self, activity_events):
        if not activity_events:
            return {"user": "unknown", "verification": "no matching Activity Log event"}

        latest = activity_events[0]
        return {
            "user": latest.get("Caller") or "unknown",
            "operation": latest.get("OperationNameValue"),
            "timestamp": latest.get("TimeGenerated"),
            "verification": "Activity Log caller; role and PIM state not queried",
        }