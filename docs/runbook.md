# Operations Runbook

## Health Checks

- GitHub Actions: inspect the latest `Terraform Drift Investigation` run. Exit code 0 means the
	refresh-only plan found no drift; exit code 2 means drift was sent for investigation; any other
	exit code is a Terraform or authentication failure.
- Function App: confirm the `investigate` HTTP trigger is deployed and inspect Application Insights
	requests/exceptions. Calls require a valid function key.
- Microsoft Foundry: confirm the configured agent version and model deployment are available and
	the Function identity still has Foundry User on the project.
- Azure AI Search: confirm the index exists, documents are present, and the Function identity has
	Search Index Data Reader.
- Log Analytics: confirm the subscription Activity Log diagnostic setting targets this workspace
	and the Function identity has Log Analytics Reader.

## Failure Triage

| Symptom | Check / response |
| --- | --- |
| Workflow cannot initialize backend | Check federated credential, subscription, state account/container names, and Storage Blob Data Contributor. |
| Terraform says resources are unchanged when a manual edit exists | Confirm the refresh-only plan is against the correct state/workspace and target subscription; inspect `resource_drift` in `terraform show -json`. |
| Function returns 401/403 | Verify the Function URL, key in `x-functions-key`, and deployment health. Rotate the key and update the GitHub environment secret if exposed. |
| Function returns 400 | Confirm the request body is a Terraform `show -json` object with an array-valued `resource_drift` field. |
| No Activity Log evidence | Confirm `resource_id` exists in the plan, diagnostic settings are enabled, query time window is appropriate, and the Function identity can query the workspace. |
| No Search excerpts | Check `AI_SEARCH_ENDPOINT`, `AI_SEARCH_INDEX`, index document count, and Search Index Data Reader. Search is full-text only in this release. |
| No Foundry recommendation | Check project endpoint, agent name/version, model deployment, region quota, Foundry User assignment, and Application Insights exceptions. |
| Sensitive values appear in a report | Stop distribution, preserve the triggering plan securely, and report a defect. The parser honors Terraform sensitive masks; providers that omit masks require additional redaction controls. |

## Safe Recovery

- Do not auto-apply a recommendation. Review the Terraform configuration and produce a normal plan
	before remediation.
- Do not apply a refresh-only plan when the intention is to restore Azure to the configured state;
	refresh-only apply updates state to match the current Azure values.
- Investigate missing Activity Log or PIM evidence as a telemetry/configuration gap, not as proof
	that no actor or privileged activation existed.
- The Function currently returns a report synchronously. There is no queue, durable retry, or
	investigation-history store in this version.

## Backup and Recovery

Protect the remote Terraform state account with Azure Storage recovery controls and restricted RBAC.
Function host keys can be rotated through the Function App keys API; update GitHub secrets after
rotation. Search indexes can be rebuilt by re-running `scripts/index_documents.py` from approved
knowledge files. Recreate a prompt agent version with `scripts/create_foundry_agent.py` after
reviewing the prompt and model.

## Production Readiness Items

Before production, add private networking and DNS, durable queue/retry handling if the plan payload
or investigation rate requires it, a retention-governed evidence store if history is required,
PIM/Graph permissions and audit validation if privileged-access assertions are required, and
approved notification integrations. Define alert thresholds, retention, regional recovery, quota,
and cost limits with the service owners.