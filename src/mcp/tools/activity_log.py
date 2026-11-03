import os

from azure.monitor.query import LogsQueryClient

from common.auth import credential


def activity_log_lookup(resource_id):

    client = LogsQueryClient(credential)

    workspace_id = os.environ["LAW_WORKSPACE_ID"]

    query = f"""
    AzureActivity
    | where ResourceId =~ '{resource_id}'
    | project
          Caller,
          OperationNameValue,
          TimeGenerated
    | top 1 by TimeGenerated desc
    """

    result = client.query_workspace(
        workspace_id,
        query=query,
        timespan=None
    )

    if not result.tables:
        return {}

    row = result.tables[0].rows[0]

    return {
        "caller": row[0],
        "operation": row[1],
        "timestamp": str(row[2])
    }