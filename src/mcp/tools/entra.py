import requests

from common.auth import credential


def resolve_user(upn):

    token = credential.get_token(
        "https://graph.microsoft.com/.default"
    )

    url = (
        f"https://graph.microsoft.com/v1.0/users/"
        f"{upn}"
    )

    response = requests.get(
        url,
        headers={
            "Authorization": f"Bearer {token.token}"
        }
    )

    response.raise_for_status()
    return response.json()