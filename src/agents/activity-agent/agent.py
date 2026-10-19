from azure.monitor.query import LogsQueryClient
from azure.identity import ManagedIdentityCredential

class ActivityLogAgent:

    def __init__(self):

        credential = ManagedIdentityCredential()

        self.client = LogsQueryClient(credential)

    def investigate(self, workspace_id, resource_id):

        query = f"""

        AzureActivity
        | where ResourceId =~ '{resource_id}'
        | project
            TimeGenerated,
            Caller,
            OperationNameValue

        | order by TimeGenerated desc
        """

        result = self.client.query_workspace(
            workspace_id,
            query,
            timespan=None
        )

        return result