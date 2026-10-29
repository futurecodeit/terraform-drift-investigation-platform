from typing import Any, TypedDict


class TerraformPlan(TypedDict, total=False):
	format_version: str
	terraform_version: str
	resource_drift: list[dict[str, Any]]
