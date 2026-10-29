# Component Diagram

## Objective

Provide logical view of all platform components.

## Components

GitHub Repository
    |
GitHub Actions
    |
Terraform
    |
Azure Landing Zone
    |
+---------------------------------------------------+
| Azure Subscription                                |
|                                                    |
| +-----------------------------------------------+ |
| | Resource Group                               | |
| |                                               | |
| | Azure Function App                           | |
| | Azure AI Foundry                             | |
| | Azure OpenAI GPT-4o                          | |
| | Azure AI Search                              | |
| | Log Analytics Workspace                      | |
| | Application Insights                         | |
| | Key Vault                                    | |
| | Container Apps Environment                   | |
| +-----------------------------------------------+ |
+---------------------------------------------------+

Container Apps

├── Activity Log MCP
├── Resource Graph MCP
├── Change Analysis MCP
├── Entra MCP
├── PIM MCP
└── Search MCP

External Integrations

├── Azure Activity Logs
├── Resource Graph
├── Microsoft Graph
├── PIM API
├── Teams
├── GitHub
└── ServiceNow