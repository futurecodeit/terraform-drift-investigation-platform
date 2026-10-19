from openai import AzureOpenAI

class RecommendationAgent:

    def __init__(self):

        self.client = AzureOpenAI(
            api_version="2024-10-01-preview",
            azure_endpoint="https://xxxxx.openai.azure.com"
        )

    def generate(self, context):

        prompt = f"""

        Generate remediation.

        {context}
        """

        result = self.client.chat.completions.create(

            model="gpt-4o",

            messages=[
              {
                "role":"user",
                "content":prompt
              }
            ]
        )

        return result.choices[0].message.content