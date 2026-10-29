import os
from datetime import timedelta

from azure.identity import DefaultAzureCredential
from azure.monitor.query import LogsQueryClient


def find_activity(
	resource_id: str,
	lookback_days: int = 30,
	workspace_id: str | None = None,
) -> list[dict]:
	workspace_id = workspace_id or os.getenv("LOG_ANALYTICS_WORKSPACE_ID")
	if not workspace_id:
		return []

	escaped_resource_id = resource_id.replace("'", "''")
	query = f"""
	AzureActivity
	| where TimeGenerated > ago({int(lookback_days)}d)
	| where ResourceId =~ '{escaped_resource_id}'
	| project TimeGenerated, Caller, OperationNameValue, ActivityStatusValue
	| order by TimeGenerated desc
	| take 10
	"""
	client = LogsQueryClient(DefaultAzureCredential())
	response = client.query_workspace(
		workspace_id,
		query,
		timespan=timedelta(days=lookback_days),
	)
	records = []
	for table in response.tables:
		columns = [column.name for column in table.columns]
		records.extend(dict(zip(columns, row)) for row in table.rows)
	return records
