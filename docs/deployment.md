# Deployment Guide

## Phase 1 - Azure Subscription Preparation

### Verify Required Providers

az provider register --namespace Microsoft.CognitiveServices

az provider register --namespace Microsoft.Search

az provider register --namespace Microsoft.App

az provider register --namespace Microsoft.Web

az provider register --namespace Microsoft.Insights

---

## Create Resource Group

az group create \
--name rg-terraform-drift-prod \
--location eastus2

---

## Create State Storage Account

Purpose:

Store Terraform Remote State

Commands:

az storage account create

az storage container create

Verify:

Terraform State Container Exists

---

## Configure Terraform Backend

backend.tf

terraform init

terraform validate

terraform plan

terraform apply

Expected:

Resource Group Created

Storage Account Created

Log Analytics Created

Function App Created

AI Search Created

Foundry Created

Container Apps Environment Created

---

## Configure Activity Logs

Create Diagnostic Settings

Destination:

Log Analytics Workspace

Validation:

AzureActivity
| take 10

Results should exist.

---

## Deploy Azure AI Foundry

Create Foundry Project

Deploy GPT-4o

Create Agent

Record:

- Endpoint
- Deployment Name

Store in Key Vault.

---

## Configure Azure AI Search

Create Index

terraform-knowledge

Upload Documents

Run:

python scripts/index_documents.py

Validation:

Search Results Return Content

---

## Deploy MCP Servers

### Activity Log MCP

Docker Build

Push Image

Deploy Container App

Health Check

---

### Resource Graph MCP

Repeat

---

### Change Analysis MCP

Repeat

---

### Entra MCP

Repeat

---

### PIM MCP

Repeat

---

### Search MCP

Repeat

---

## Publish Azure Function

func azure functionapp publish

Validation:

GET /health

Returns 200

---

## Register MCP Tools

Foundry Portal

Add Custom Tools

Register:

ActivityLogMCP

ResourceGraphMCP

ChangeAnalysisMCP

EntraMCP

PIMMCP

AISearchMCP

---

## Configure GitHub OIDC

Create Federated Credential

Assign Roles:

Contributor

Storage Blob Data Contributor

Monitoring Reader

Reader

---

## Configure GitHub Actions

Workflow 1

Terraform Validation

Workflow 2

Terraform Apply

Workflow 3

Drift Investigation

---

## End-to-End Test

Modify:

Resource Group Tag

Run:

terraform plan

Expected:

Drift Detected

Function Triggered

Agent Executes

Report Generated
