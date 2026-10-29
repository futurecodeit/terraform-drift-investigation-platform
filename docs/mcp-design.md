# MCP Design

## Purpose

Expose Azure services as reusable AI tools.

## Why MCP

Without MCP:

Agent
 |
 Direct Azure API Calls

Problems

- Tight coupling
- Difficult maintenance
- Duplicate code

With MCP

Agent
 |
 MCP Tools
 |
 Azure APIs

Benefits

- Reusable
- Agent independent
- Standardized interface

---

# Activity Log MCP

Methods

get_activity_logs()

Returns

- Caller
- Operation
- Event Timestamp

Source

Azure Activity Logs

Role Required

Monitoring Reader

---

# Resource Graph MCP

Methods

query_resource()

Source

Azure Resource Graph

Returns

Current Resource Configuration

---

# Change Analysis MCP

Methods

get_resource_diff()

Returns

Property-Level Changes

---

# Entra MCP

Methods

resolve_user()

Returns

User Details

Department

Manager

Location

---

# PIM MCP

Methods

check_pim_activation()

Returns

Activated Roles

Activation Time

Duration

---

# Search MCP

Methods

search_knowledge()

Returns

Runbooks

SOPs

Terraform Standards