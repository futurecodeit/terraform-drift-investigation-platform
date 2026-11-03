import os

from azure.ai.projects import AIProjectClient

from azure.identity import DefaultAzureCredential


def generate_rca(context):

    endpoint = os.environ[
        "FOUNDRY_PROJECT_ENDPOINT"
    ]

    client = AIProjectClient(
        endpoint=endpoint,
        credential=DefaultAzureCredential()
    )

    # Later:
    # Invoke deployed Foundry Agent

    return {
        "recommendation":
        "Run terraform apply to restore state"
    }