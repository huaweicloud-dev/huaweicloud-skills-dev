# Data Flow Diagram

```mermaid
flowchart TD
    A[Agent receives query request] --> B{What to query?}

    B -->|Attack events| C[hcloud WAF ListEvent]
    B -->|Event detail| D[hcloud WAF ShowEvent]
    B -->|Access/Protection logs| E[hcloud WAF ListEventLog]
    B -->|Statistics overview| F[hcloud WAF ListStatistics]
    B -->|Threat overview| G[hcloud WAF ListThreats]
    B -->|Top source IPs| H[hcloud WAF ListTopIp]

    C --> I[WAF ListEvents API]
    D --> J[WAF ShowEvent API]
    E --> K[WAF ListEventLog API]
    F --> L[WAF Statistics API]
    G --> M[WAF Threats API]
    H --> N[WAF TopIp API]

    I --> O[JSON response: events, total]
    J --> O
    K --> O
    L --> O
    M --> O
    N --> O

    O --> P[Agent summarizes results for user]
```

## Explanation

1. The agent identifies the query intent (events / detail / logs / statistics / threats / top IPs).
2. It invokes the corresponding read-only `hcloud WAF` command with `--cli-region` and `--project_id`.
3. WAF APIs return JSON; the agent formats the result (counts, top items, event details) for the user.
4. All operations are GET queries — no WAF resources are modified.
