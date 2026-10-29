class AuditAgent:
	def assess(self, drift, activity, knowledge_evidence):
		missing = []
		if not drift.get("resource_id"):
			missing.append("Azure resource ID is unavailable in the Terraform plan.")
		if not activity:
			missing.append("No matching Activity Log events were returned.")
		if not knowledge_evidence:
			missing.append("No matching standards or runbooks were returned by AI Search.")
		return {
			"evidence_complete": not missing,
			"missing_evidence": missing,
			"pim_checked": False,
		}
