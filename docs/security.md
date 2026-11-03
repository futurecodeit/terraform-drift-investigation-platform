# Security Design

## Identity Strategy

Use:

Managed Identity

Avoid:

Client Secrets

Passwords

PAT Tokens

---

## Authorization

Roles

### Function Identity

AI Foundry User

Search Index Reader

Log Analytics Reader

Reader

---

### MCP Identity

Monitoring Reader

Reader

Directory Reader

Resource Graph Reader

---

## Secrets

Store in:

Azure Key Vault

Examples:

OpenAI Secrets

Search Keys

Graph Credentials

Certificates

---

# Network Security

Enable:

Private Endpoints

Disable:

Public Access

Resources:

Function App

Key Vault

Foundry

AI Search

Storage Account

---

# Logging

Enable:

Diagnostic Settings

App Insights

Activity Logs

Audit Logs

---

# Compliance

Encrypt Data At Rest

Encrypt Data In Transit

TLS 1.2+

RBAC Only

Least Privilege