# Production Runbook

## Platform Name

AI-Powered Terraform Drift Investigation Platform

---

# Purpose

Provides operational guidance for:

- Monitoring
- Troubleshooting
- Recovery
- Validation

---

# Components

| Component | Responsibility |
|------------|---------------|
| GitHub Actions | Drift Detection |
| Service Bus | Queue Processing |
| Azure Function | Orchestration |
| AI Foundry | Agent Execution |
| Azure OpenAI | RCA Generation |
| AI Search | RAG Retrieval |
| Cosmos DB | Investigation History |

---

# Health Checks

## GitHub Actions

Verify:

```bash
terraform plan
```

Expected:

```text
Success
```

---

## Service Bus

Check:

```text
Active Messages
Dead-letter Messages
```

Expected:

```text
Dead Letters = 0
```

---

## Azure Function

Verify:

```text
Availability > 99%
```

Application Insights:

```kusto
requests
| order by timestamp desc
```

---

## Azure OpenAI

Verify:

```text
Model Deployment State
```

Expected:

```text
Succeeded
```

---

## AI Search

Verify:

```text
Index Status
Indexer Runs
Document Counts
```

---

# Operational Validation

## Test Drift Scenario

Terraform:

```hcl
node_count = 3
```

Azure Portal:

```text
Scale to 5
```

Execute:

```bash
terraform plan
```

Expected:

```text
Drift Detected
```

---

# RCA Validation

Expected Report:

```text
Resource:
aks-prod

Changed By:
john.doe@contoso.com

Property:
node_count

Old Value:
3

New Value:
5
```

---

# Troubleshooting

## No Drift Detected

Check:

```bash
terraform refresh
terraform plan
```

Validate:

```text
Terraform state consistency
```

---

## User Not Identified

Check:

```kusto
AzureActivity
| where Caller != ""
```

Verify:

```text
Diagnostic Settings Enabled
```

---

## Change Analysis Missing

Check:

```text
Resource Change Analysis
```

Validate:

```text
Resource Type Supported
```

---

## AI Search Returns No Results

Check:

```text
Indexer Status
Embedding Generation
Document Count
```

---

## OpenAI Failure

Check:

```text
Deployment Status
Quota
Tokens
```

Application Insights:

```kusto
exceptions
| order by timestamp desc
```

---

## Teams Notification Failure

Validate:

```text
Webhook URL
Managed Identity Permissions
Firewall Rules
```

---

# Service Bus Recovery

## Dead Letter Queue

If messages appear:

```text
DLQ > 0
```

Action:

1. Inspect payload
2. Fix parsing issue
3. Replay message

---

# Disaster Recovery

## Search Index Failure

Recovery:

```text
Rebuild Search Index
Re-run Ingestion Pipeline
```

---

## Function Failure

Recovery:

```bash
az functionapp restart
```

---

## Cosmos DB Failure

Recovery:

```text
Restore from Point-In-Time Restore
```

---

# Monitoring Dashboards

## Recommended Metrics

### Platform

- Drift Count
- Investigation Count
- Investigation Duration

### AI

- Token Consumption
- Prompt Failures
- Completion Time

### Platform Operations

- Queue Depth
- Dead Letter Count
- Function Failures

---

# SLA

| Service | SLA |
|----------|------|
| Drift Detection | < 2 Minutes |
| Investigation | < 60 Seconds |
| Teams Alert | < 90 Seconds |
| GitHub Comment | < 90 Seconds |

---

# Escalation Path

L1

Platform Operations Team

L2

Cloud Platform Engineering Team

L3

Azure AI Foundry Team

L4

Azure Support