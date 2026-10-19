from msgraph import GraphServiceClient

class IdentityAgent:

    def get_identity_details(self, user_id):

        return {
            "user": "john@contoso.com",
            "role": "Contributor",
            "pim": True
        }