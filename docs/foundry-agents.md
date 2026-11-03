# Foundry Agents Design

## Agent Architecture

Orchestrator Agent

├── Terraform Analyzer
├── Activity Investigator
├── Identity Investigator
├── Knowledge Agent
└── Recommendation Agent

---

# Terraform Analyzer

Input

Terraform Plan JSON

Output

Detected Drift

Example

tags.environment

---

# Activity Investigator

Tool

Activity Log MCP

Purpose

Determine

Who changed resource

When

How

---

# Identity Investigator

Tool

Entra MCP

Purpose

Resolve identity

---

# Knowledge Agent

Tool

Search MCP

Purpose

Retrieve Governance Standards

Runbooks

---

# Recommendation Agent

Model

GPT-4o

Purpose

Generate RCA

Generate Remediation

Generate Incident Summary