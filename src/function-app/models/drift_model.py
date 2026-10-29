from typing import Any, TypedDict


class PropertyChange(TypedDict):
	path: str
	before: Any
	after: Any


class DriftRecord(TypedDict):
	address: str
	resource_type: str
	resource_id: str | None
	actions: list[str]
	changes: list[PropertyChange]
