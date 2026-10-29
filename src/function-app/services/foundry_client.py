import json
import os

from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential


def generate_recommendation(report: dict) -> str | None:
	endpoint = os.getenv("FOUNDRY_PROJECT_ENDPOINT")
	agent_name = os.getenv("FOUNDRY_AGENT_NAME")
	if not endpoint or not agent_name:
		return None

	project = AIProjectClient(
		endpoint=endpoint,
		credential=DefaultAzureCredential(),
	)
	client = project.get_openai_client(agent_name=agent_name)
	response = client.responses.create(
		input=(
			"Analyze this Terraform drift evidence. State only conclusions supported by the evidence; "
			"identify uncertainty, assess impact, and suggest reversible remediation. Do not claim "
			"that a person, PIM activation, or policy violation was verified unless the evidence "
			"contains it. Never repeat secrets. Return concise Markdown.\n\n"
			+ json.dumps(report, default=str)
		),
		max_output_tokens=1200,
	)
	return response.output_text
