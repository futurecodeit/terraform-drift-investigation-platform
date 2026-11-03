import requests

from common.auth import credential


def get_change_history(resource_id):

    token = credential.get_token(
        "https://management.azure.com/.default"
    )

    url = (
        f"https://management.azure.com"
        f"{resource_id}"
        f"/providers/Microsoft.ChangeAnalysis"
        f"/resourceChanges"
        f"?api-version=2022-05-01"
    )

    response = requests.get(
        url,
        headers={
            "Authorization": f"Bearer {token.token}"
        }
    )

    response.raise_for_status()
    return response.json()