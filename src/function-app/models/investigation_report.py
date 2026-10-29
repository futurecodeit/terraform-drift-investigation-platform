from typing import TypedDict

from .drift_model import DriftRecord


class InvestigationReport(TypedDict, total=False):
	terraform_version: str | None
	format_version: str | None
	drift_count: int
	drifts: list[DriftRecord]
	recommendation: str | None
	warnings: list[str]
