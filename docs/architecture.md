# AI-Powered Terraform Drift Investigation Platform

## Overview

The AI-Powered Terraform Drift Investigation Platform automatically detects configuration drift in Azure resources managed by Terraform and identifies:

- Who changed the resource
- What changed
- When it changed
- How it was changed
- Whether PIM was used
- Whether the change complies with platform standards
- Recommended remediation actions

The solution combines:

- GitHub Actions
- Terraform
- Azure Functions
- Azure AI Foundry
- Azure OpenAI GPT-4o
- Azure AI Search
- Azure Resource Graph
- Azure Activity Logs
- Resource Change Analysis
- Microsoft Entra ID
- Microsoft Entra PIM
- Azure Monitor
- Service Bus
- Cosmos DB

---

# Architecture Goals

## Functional Goals

- Detect Terraform Drift
- Attribute resource changes to users
- Correlate audit and resource telemetry
- Generate RCA automatically
- Notify engineering teams
- Maintain investigation history

---

## Non-Functional Goals

### Security

- Managed Identity Everywhere
- Private Endpoints
- No Secrets in Code
- Key Vault Integration

### Reliability

- Queue-based processing
- Retry mechanisms
- Dead Letter Queue support

### Scalability

- Event-driven architecture
- Agent-based processing

### Observability

- Distributed tracing
- Centralized logging
- Investigation metrics

---

# High-Level Architecture

## CI/CD Layer

Components:

- GitHub Repository
- GitHub Actions
- Terraform State Storage

Responsibilities:

- Execute terraform plan
- Export tfplan.json
- Trigger drift investigation

---

## Integration Layer

Components:

- Azure Service Bus
- Azure Function App

Responsibilities:

- Accept drift events
- Manage investigation lifecycle
- Orchestrate agent execution

---

## Investigation Layer

### Terraform Agent

Extracts:

- Resource Name
- Resource Type
- Changed Properties
- Before State
- After State

---

### Activity Log Agent

Identifies:

- Caller
- Operation
- Source
- Timestamp

---

### Change Analysis Agent

Identifies:

- Exact property change
- Before value
- After value

---

### Identity Agent

Retrieves:

- User
- Group Membership
- Assigned Role
- PIM Activation Details

---

### RAG Agent

Queries:

- Terraform Repositories
- Runbooks
- Architecture Standards
- Operations Documentation

---

### Correlation Agent

Correlates all collected evidence.

Produces:

- Investigation Context

---

### Recommendation Agent

Uses GPT-4o to generate:

- Root Cause Analysis
- Risk Assessment
- Remediation Steps

---

# Data Sources

## Azure Activity Logs

Used To:

- Identify actor
- Identify operation

---

## Azure Resource Change Analysis

Used To:

- Determine exact property changes

---

## Azure Resource Graph

Used To:

- Retrieve current resource state

---

## Microsoft Entra ID

Used To:

- Resolve user information

---

## Microsoft Entra PIM

Used To:

- Verify privileged access activations

---

# AI Layer

## Azure AI Foundry

Provides:

- Agent orchestration
- Tool chaining
- Workflow execution

---

## Azure OpenAI

Model:

```text
GPT-4o
```

Task:

- Generate RCA
- Generate Recommendations

---

## Azure AI Search

Provides:

- Vector Search
- Semantic Search
- Hybrid Search

Indexed Data:

```text
Terraform Modules
Standards
Runbooks
Architecture Documents
```

---

# Security Architecture

## Managed Identity

Used By:

- Function App
- AI Foundry
- Search
- OpenAI

---

## Key Vault

Stores:

- Webhook URLs
- ServiceNow Credentials
- Application Secrets

---

## Private Endpoints

Enabled For:

- OpenAI
- AI Search
- Key Vault
- Cosmos DB
- Storage

---

# Storage Components

## Storage Account

Purpose:

- Terraform State
- RAG Data

---

## Cosmos DB

Purpose:

- Investigation History
- Audit Trail
- RCA Repository

---

# Outputs

## Teams

Real-time alerts

## GitHub

PR comments

## ServiceNow

Incident generation

## Cosmos DB

Audit repository