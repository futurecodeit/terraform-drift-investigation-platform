from collections.abc import Mapping
from typing import Any


REDACTED = "[REDACTED]"


def _changes(
    before: Any,
    after: Any,
    before_sensitive: Any,
    after_sensitive: Any,
    path: str = "",
) -> list[dict[str, Any]]:
    if isinstance(before, Mapping) and isinstance(after, Mapping):
        result = []
        for key in sorted(set(before) | set(after)):
            child_path = f"{path}.{key}" if path else str(key)
            result.extend(
                _changes(
                    before.get(key),
                    after.get(key),
                    before_sensitive.get(key, False)
                    if isinstance(before_sensitive, Mapping)
                    else False,
                    after_sensitive.get(key, False)
                    if isinstance(after_sensitive, Mapping)
                    else False,
                    child_path,
                )
            )
        return result

    if isinstance(before, list) and isinstance(after, list):
        result = []
        for index in range(max(len(before), len(after))):
            before_value = before[index] if index < len(before) else None
            after_value = after[index] if index < len(after) else None
            before_mask = (
                before_sensitive[index]
                if isinstance(before_sensitive, list) and index < len(before_sensitive)
                else False
            )
            after_mask = (
                after_sensitive[index]
                if isinstance(after_sensitive, list) and index < len(after_sensitive)
                else False
            )
            result.extend(
                _changes(
                    before_value,
                    after_value,
                    before_mask,
                    after_mask,
                    f"{path}[{index}]",
                )
            )
        return result

    if before == after:
        return []

    return [
        {
            "path": path or "$",
            "before": REDACTED if before_sensitive else before,
            "after": REDACTED if after_sensitive else after,
        }
    ]


def analyze_plan(plan: Any) -> dict[str, Any]:
    """Return resource drift from Terraform's `terraform show -json` output."""
    if not isinstance(plan, Mapping):
        raise ValueError("Terraform plan JSON must be an object.")

    resource_drift = plan.get("resource_drift", [])
    if not isinstance(resource_drift, list):
        raise ValueError("Terraform plan field 'resource_drift' must be an array.")

    drifts = []
    for resource in resource_drift:
        if not isinstance(resource, Mapping):
            continue

        change = resource.get("change")
        if not isinstance(change, Mapping):
            continue

        actions = change.get("actions", [])
        if not isinstance(actions, list) or actions == ["no-op"]:
            continue

        changes = _changes(
            change.get("before"),
            change.get("after"),
            change.get("before_sensitive", {}),
            change.get("after_sensitive", {}),
        )
        if not changes:
            continue

        drifts.append(
            {
                "address": resource.get("address", "unknown"),
                "resource_type": resource.get("type", "unknown"),
                "resource_id": (change.get("after") or change.get("before") or {}).get("id")
                if isinstance(change.get("after") or change.get("before"), Mapping)
                else None,
                "actions": actions,
                "changes": changes,
            }
        )

    return {
        "terraform_version": plan.get("terraform_version"),
        "format_version": plan.get("format_version"),
        "drift_count": len(drifts),
        "drifts": drifts,
    }