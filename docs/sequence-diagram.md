# Terraform Drift Investigation Sequence Diagram

```mermaid
sequenceDiagram

participant Dev as Developer
participant GH as GitHub Actions
participant TF as Terraform
participant SB as Service Bus
participant FA as Azure Function

participant TA as Terraform Agent
participant AA as Activity Agent
participant CA as Change Agent
participant IA as Identity Agent
participant RA as RAG Agent

participant COR as Correlation Agent
participant GPT as Azure OpenAI

participant TM as Teams
participant GHC as GitHub PR
participant SN as ServiceNow

Dev->>GH: Push Change

GH->>TF: terraform plan

TF-->>GH: tfplan.json

GH->>SB: Publish Drift Event

SB->>FA: Trigger Investigation

FA->>TA: Analyze tfplan

TA-->>FA: Drift Details

par Evidence Collection

FA->>AA: Query Activity Logs
AA-->>FA: User Activity

and

FA->>CA: Query Change Analysis
CA-->>FA: Property Changes

and

FA->>IA: Query Entra/PIM
IA-->>FA: User Context

and

FA->>RA: Query AI Search
RA-->>FA: Expected Configuration

end

FA->>COR: Correlate Evidence

COR-->>FA: Investigation Context

FA->>GPT: Generate RCA

GPT-->>FA: RCA Report

FA->>GHC: Post PR Comment

FA->>TM: Send Alert

FA->>SN: Create Incident
```

---

# Investigation Timeline

1. Drift detected
2. Investigation triggered
3. Evidence collected
4. User identified
5. Configuration baseline retrieved
6. RCA generated
7. Notifications dispatched