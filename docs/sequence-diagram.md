# Investigation Sequence

```mermaid
sequenceDiagram
	participant GH as GitHub Actions
	participant TF as Terraform
	participant FA as Azure Function
	participant LA as Log Analytics
	participant SI as Azure AI Search
	participant F as Microsoft Foundry Agent

	GH->>TF: terraform plan -refresh-only -detailed-exitcode
	TF-->>GH: exit 0 (no drift) or exit 2 (drift)
	GH->>TF: terraform show -json drift.tfplan
	TF-->>GH: plan JSON with resource_drift
	GH->>FA: HTTPS POST + x-functions-key
	FA->>FA: Parse resource_drift; redact sensitive values
	opt Resource ID and Log Analytics configured
		FA->>LA: Query recent AzureActivity for resource ID
		LA-->>FA: Caller, operation, timestamp, status
	end
	opt Search endpoint and index configured
		FA->>SI: Full-text search for resource and changed properties
		SI-->>FA: Sourced standards/runbook excerpts
	end
	opt Foundry agent configured
		FA->>F: Evidence-bound recommendation request
		F-->>FA: Summary, risk, recommended verification/remediation
	end
	FA-->>GH: JSON report with drift, evidence, warnings, recommendation
```

The request path is synchronous. No Service Bus, persistence layer, or notification system is
provisioned in this release.