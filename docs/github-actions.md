# GitHub Actions Design

## Workflow 1

terraform-validate.yml

Steps

fmt

validate

plan

---

## Workflow 2

terraform-apply.yml

Manual Approval

apply

---

## Workflow 3

drift-investigation.yml

Schedule

Every 4 Hours

---

Flow

terraform plan

if drift

trigger Function

receive RCA

publish report

---

Authentication

OIDC

No Client Secrets