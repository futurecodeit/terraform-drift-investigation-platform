import os

from azure.identity import DefaultAzureCredential, ManagedIdentityCredential


credential = (
    ManagedIdentityCredential()
    if os.getenv("CONTAINER_APP_NAME")
    else DefaultAzureCredential()
)