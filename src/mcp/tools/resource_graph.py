from azure.mgmt.resourcegraph import ResourceGraphClient
from azure.mgmt.resourcegraph.models import QueryRequest

from common.auth import credential


def query_resource_state(subscription_id, resource_id):

    client = ResourceGraphClient(
        credential=credential
    )

    query = f"""
    Resources
    | where id =~ '{resource_id}'
    """

    response = client.resources(
        QueryRequest(
            subscriptions=[subscription_id],
            query=query
        )
    )

    return response.data