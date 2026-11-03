# terraform-drift-investigation-platform

## Repository structure

```text
terraform-drift-investigation-platform/
├── .github/
│   └── workflows/
│       ├── drift-investigation.yml
│       ├── mcp-gateway-image.yml
│       ├── terraform-apply.yml
│       └── terraform-plan.yml
├── docs/
│   ├── architecture.md
│   ├── component-diagram.md
│   ├── deployment.md
│   ├── dia.md
│   ├── disaster-recovery.md
│   ├── foundry-agents.md
│   ├── github-actions.md
│   ├── manual-steps.md
│   ├── mcp-design.md
│   ├── monitoring.md
│   ├── operational-guide.md
│   ├── rag-design.md
│   ├── runbook.md
│   ├── security.md
│   ├── sequence-diagram.md
│   ├── terraform-design.md
│   ├── testing-guide.md
│   ├── troubleshooting.md
│   └── *.png
├── environments/
│   ├── dev/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── provider.tf
│   │   ├── terraform.tfvars
│   │   └── variables.tf
│   └── qa/
├── knowledge/
│   └── read.md
├── modules/
│   ├── activity-logs/
│   ├── ai-search/
│   ├── app-service-plan/
│   ├── application-insights/
│   ├── azure-ai-foundry/
│   ├── containerapps/
│   ├── firewall/
│   ├── function-app/
│   ├── github-integration/
│   ├── keyvault/
│   ├── log-analytics/
│   ├── managed-identity/
│   ├── monitor-diagnostics/
│   ├── private-dns/
│   ├── private-endpoints/
│   ├── resource-graph/
│   ├── resource-group/
│   ├── role-assignments/
│   ├── service-bus/
│   ├── storage-account/
│   ├── teams-webhook/
│   ├── terraform-state/
│   └── virtual-network/
├── rag-data/
│   ├── architecture/
│   ├── runbooks/
│   ├── standards/
│   └── terraform-modules/
├── scripts/
│   ├── bootstrap.sh
│   ├── create_foundry_agent.py
│   ├── generate_embeddings.py
│   └── index_documents.py
├── src/
│   ├── agents/
│   │   ├── activity-agent/
│   │   ├── audit-agent/
│   │   ├── change-analysis-agent/
│   │   ├── correlation-agent/
│   │   ├── github/
│   │   ├── identity-agent/
│   │   ├── rag-agent/
│   │   ├── recommendation-agent/
│   │   ├── team-alert/
│   │   └── terraform-agent/
│   ├── function-app/
│   │   ├── investigate/
│   │   ├── models/
│   │   ├── services/
│   │   ├── drift.py
│   │   ├── function_app.py
│   │   ├── host.json
│   │   └── requirements.txt
│   ├── integrations/
│   │   ├── email/
│   │   ├── github/
│   │   ├── servicenow/
│   │   └── teams/
│   ├── kusto/
│   │   └── *.kql
│   ├── mcp/
│   │   ├── activity-log-mcp/
│   │   ├── common/
│   │   └── tools/
│   ├── prompts/
│   │   └── *.txt
│   └── rag/
│       ├── chunkers/
│       ├── documents/
│       ├── embeddings/
│       ├── indexers/
│       └── loaders/
├── tests/
│   ├── agent-tests/
│   ├── integration-tests/
│   └── kusto-tests/
├── .gitignore
├── LICENSE
├── README.md
└── local.settings.example.json
```