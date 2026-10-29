# Troubleshooting Guide

## Problem

Terraform Plan Shows No Drift

Checks

terraform refresh

terraform plan

Resource Exists

State Exists

---

## Problem

Function Returns 500

Checks

Application Insights

Managed Identity

Foundry Endpoint

Search Endpoint

---

## Problem

Agent Cannot Call MCP

Checks

Tool Registration

MCP Health Endpoint

Authentication

Network Access

---

## Problem

Search Returns Nothing

Checks

Index Exists

Documents Indexed

Permissions

---

## Problem

No User Attribution

Checks

Activity Log Exists

Diagnostics Enabled

Graph Permissions Present

---

## Problem

PIM Role Not Available

Checks

User Activated PIM

PIM Logs Available

Graph Access Granted

---

## Problem

GitHub OIDC Fails

Checks

Federated Credential

Subject Claims

Repository Name

Environment Name

Role Assignments

---

## Useful Queries

Activity Logs

AzureActivity
| take 100

Function Errors

exceptions
| order by timestamp desc

Search Health

requests
| order by timestamp desc