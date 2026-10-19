from azure.mgmt.resourcegraph import ResourceGraphClient

class ChangeAnalysisAgent:

    def __init__(self, credential):

        self.client = ResourceGraphClient(credential)

    def get_changes(self, resource_id):

        query = f"""
        resourcechanges
        | where targetResourceId =~ '{resource_id}'
        """

        return query
