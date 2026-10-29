# Terraform Drift Attribution Platform Architecture

## Purpose

This platform detects Terraform drift in Azure environments and automatically identifies:

- What changed
- Who changed it
- When it changed
- How it changed
- Which role was used
- Recommended remediation

using Azure AI Foundry, MCP Servers, Azure OpenAI, Azure AI Search and Azure monitoring services.

---

# Business Flow

Terraform Infrastructure
        |
GitHub Actions
        |
terraform plan
        |
Drift Detected
        |
Azure Function
        |
Azure AI Foundry Agent
        |
+----------------------------------+
| Activity Log MCP                 |
| Resource Graph MCP               |
| Change Analysis MCP              |
| Entra MCP                        |
| PIM MCP                          |
| AI Search MCP                    |
+----------------------------------+
        |
Azure OpenAI GPT-4o
        |
Root Cause Analysis
        |
Teams / GitHub / ServiceNow

---

# Components

## GitHub

Purpose:
- Source Control
- CI/CD

Repositories:
- terraform-infra
- terraform-drift-platform

---

## Azure Function App

Purpose:
- Central Orchestration Layer

Responsibilities:
- Receive Terraform drift events
- Call Foundry Agent
- Return RCA report

---

## Azure AI Foundry

Purpose:
- Multi-agent orchestration

Agents:

1 Terraform Analyzer Agent

Responsibilities:
- Parse terraform plan JSON
- Extract drifts

2 Activity Investigation Agent

Responsibilities:
- Determine resource modifier

3 Identity Agent

Responsibilities:
- Resolve user identity

4 Knowledge Agent

Responsibilities:
- Retrieve runbooks

5 Recommendation Agent

Responsibilities:
- Generate RCA

---

## MCP Components

### Activity Log MCP

Functions:

- get_activity_logs()

Data Source:

- Azure Activity Logs

---

### Resource Graph MCP

Functions:

- query_resource()

Data Source:

- Azure Resource Graph

---

### Change Analysis MCP

Functions:

- get_changes()

Data Source:

- Resource Change Analysis

---

### Entra MCP

Functions:

- resolve_user()

Data Source:

- Microsoft Graph API

---

### PIM MCP

Functions:

- get_role_activation()

Data Source:

- Microsoft Entra PIM

---

### AI Search MCP

Functions:

- search_knowledge()

Data Source:

- Azure AI Search

---

# Network Architecture

Hub-Spoke Model

Hub

- Firewall
- DNS

Spoke

- Function App
- Container Apps
- AI Services

Private Endpoints

- Foundry
- Search
- Key Vault
- Storage

---

# Monitoring

- Azure Monitor
- Log Analytics
- Application Insights

---

# High Availability

RPO = 15 Minutes

RTO = 30 Minutes

Multi-zone services where supported.