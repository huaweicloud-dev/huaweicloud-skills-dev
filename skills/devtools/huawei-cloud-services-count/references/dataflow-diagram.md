# Data Flow Diagram

```mermaid
graph TD
    User[User / Agent] -->|Trigger: count query| Skill[huawei-cloud-services-count]
    Skill -->|Step 1: hcloud meta download| CLI[KooCLI]
    CLI -->|Refresh metadata| Metadata[(~/.hcloud/metaRepo/services_en.json)]
    Skill -->|Step 2: Read & parse| Metadata
    Skill -->|Step 3: Count entries| Count[Python JSON parser]
    Count -->|Result| Output["Print: Huawei Cloud Services Count: N"]
    Output --> User
```

## Flow Description

1. User triggers the Skill with a query like "how many Huawei Cloud services are there?"
2. Skill refreshes the local metadata cache via `hcloud meta download`
3. Skill reads `services_en.json` and parses the service entries
4. Python script counts all service entries
5. The total count is printed as output