from services.mcp_service import (
    activity_log_lookup,
    get_change_history,
    get_resource_state
)

from services.foundry_service import (
    generate_rca
)


def investigate(
    terraform_plan
):

    resource_id = terraform_plan["resource_id"]

    user = activity_log_lookup(
        resource_id
    )

    state = get_resource_state(
        resource_id
    )

    diff = get_change_history(
        resource_id
    )

    recommendation = generate_rca(
        {
            "user": user,
            "state": state,
            "diff": diff
        }
    )

    return {
        "user": user,
        "state": state,
        "diff": diff,
        "recommendation": recommendation
    }