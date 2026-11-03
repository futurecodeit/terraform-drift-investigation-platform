import os
from typing import Any

import requests
from azure.identity import DefaultAzureCredential, ManagedIdentityCredential

MCP_URL = os.getenv("MCP_GATEWAY_URL", "").rstrip("/")
MCP_SCOPE = os.getenv("MCP_GATEWAY_SCOPE", "")
CREDENTIAL = (
    ManagedIdentityCredential()
    if os.getenv("WEBSITE_INSTANCE_ID")
    else DefaultAzureCredential()
)


def _post(path: str, payload: dict[str, str]) -> Any:
    if not MCP_URL:
        raise RuntimeError("MCP_GATEWAY_URL is not configured.")
    if not MCP_SCOPE:
        raise RuntimeError("MCP_GATEWAY_SCOPE is not configured.")

    token = CREDENTIAL.get_token(MCP_SCOPE)
    response = requests.post(
        f"{MCP_URL}{path}",
        headers={"Authorization": f"Bearer {token.token}"},
        json=payload,
        timeout=30,
    )
    response.raise_for_status()
    return response.json()


def activity_log_lookup(resource_id: str) -> Any:
    return _post("/tools/activity-log", {"resource_id": resource_id})


def get_resource_state(resource_id: str) -> Any:
    return _post("/tools/resource-graph", {"resource_id": resource_id})


def get_change_history(resource_id: str) -> Any:
    return _post("/tools/change-analysis", {"resource_id": resource_id})