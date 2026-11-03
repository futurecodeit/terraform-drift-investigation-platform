# RAG Design

## Objective

Supply organizational context to Foundry Agents.

---

# Data Sources

Terraform Repository

Architecture Documents

Runbooks

SOPs

Incident Reports

Security Standards

Compliance Standards

---

# Index Structure

Index Name

terraform-knowledge

Fields

id

title

content

source

category

createdDate

---

# Retrieval Flow

Agent
 |
Search MCP
 |
Azure AI Search
 |
Relevant Documents
 |
GPT-4o

---

# Chunking Strategy

Chunk Size

1000 Tokens

Overlap

200 Tokens

---

# Security

PII Removal

Secret Detection

Index Encryption

Private Endpoint Enabled