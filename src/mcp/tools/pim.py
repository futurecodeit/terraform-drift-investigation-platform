import requests

from common.auth import credential


def check_pim_activation(user_id):

    token = credential.get_token(
        "https://graph.microsoft.com/.default"
    )

    url = (
        "https://graph.microsoft.com/beta/"
        "roleManagement/directory/"
        "roleAssignmentScheduleInstances"
    )

    response = requests.get(
        url,
        headers={
            "Authorization": f"Bearer {token.token}"
        }
    )

    response.raise_for_status()
    return response.json()