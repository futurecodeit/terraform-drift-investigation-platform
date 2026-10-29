import os
from pathlib import Path

from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import PromptAgentDefinition
from azure.identity import DefaultAzureCredential


def main() -> None:
    endpoint = os.environ.get("FOUNDRY_PROJECT_ENDPOINT")
    agent_name = os.environ.get("FOUNDRY_AGENT_NAME", "terraform-drift-investigator")
    model = os.environ.get("FOUNDRY_MODEL_DEPLOYMENT")
    if not endpoint or not model:
        raise SystemExit("Set FOUNDRY_PROJECT_ENDPOINT and FOUNDRY_MODEL_DEPLOYMENT first.")

    prompt_path = Path("src/agents/recommendation-agent/prompt.txt")
    instructions = prompt_path.read_text(encoding="utf-8").strip()
    project = AIProjectClient(endpoint=endpoint, credential=DefaultAzureCredential())
    agent = project.agents.create_version(
        agent_name=agent_name,
        definition=PromptAgentDefinition(model=model, instructions=instructions),
    )
    print(f"Created Foundry agent '{agent.name}' version {agent.version} (id: {agent.id}).")


if __name__ == "__main__":
    main()