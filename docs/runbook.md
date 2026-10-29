# Operations Runbook

## Incident Types

P1

Platform Down

P2

Drift Investigation Failure

P3

Agent Degradation

P4

Search Index Failure

---

# Daily Checks

Azure Function Healthy

Container Apps Healthy

Agent Health Healthy

Search Index Healthy

Activity Logs Arriving

---

# Terraform Drift Alert

When Alert Arrives

Step 1

Read Drift Report

Step 2

Confirm Changed Resource

Step 3

Confirm Responsible User

Step 4

Determine Approved Change

If Approved

Update Terraform

Commit

Apply

If Not Approved

terraform apply

Restore State

---

# Function Failure

Symptoms

500 Error

Actions

Application Insights

Check Exceptions

Restart Function App

---

# MCP Failure

Check

Container App Revision

Logs

Health Endpoint

Redeploy if Required

---

# Search Failure

Check:

Index Exists

Documents Indexed

Access Role Present

Re-run Indexing Job

---

# Disaster Recovery

Restore Terraform State

Re-deploy Infrastructure

Recreate MCP Servers

Rebuild Search Index

Re-register Foundry Agents
