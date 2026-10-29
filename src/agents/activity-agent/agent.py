import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "function-app"))

from services.activity_log_client import find_activity

class ActivityLogAgent:

    def investigate(self, workspace_id, resource_id):
        return find_activity(resource_id, workspace_id=workspace_id)