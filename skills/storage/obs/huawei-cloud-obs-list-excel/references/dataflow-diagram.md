# Data Flow Diagram

```mermaid
flowchart TD
    A[User/Agent] -->|"python3 obs-list-excel.py --region cn-north-4"| B[Skill: obs-list-excel]
    B --> C{Detect Credentials}
    C -->|AK/SK found| D[Initialize OBS SDK Client]
    C -->|Missing| X[Raise QualityError C01]
    D --> E[OBS API: ListBuckets]
    E -->|Buckets returned| F{For each bucket}
    F --> G[OBS API: ListObjects]
    G --> H{Aggregate data}
    H --> I[Generate Excel Report]
    I --> J[openpyxl: Create Workbook]
    J --> K[Sheet 1: Buckets Summary]
    J --> L[Sheet 2: Objects Detail]
    K --> M[Save /tmp/obs-inventory.xlsx]
    L --> M
    M --> N[Report file path to Agent]

    style A fill:#e1f5fe,stroke:#01579b
    style B fill:#f3e5f5,stroke:#7b1fa2
    style E fill:#fff3e0,stroke:#e65100
    style G fill:#fff3e0,stroke:#e65100
    style K fill:#e8f5e9,stroke:#1b5e20
    style L fill:#e8f5e9,stroke:#1b5e20
    style M fill:#fce4ec,stroke:#c62828
    style X fill:#ffebee,stroke:#b71c1c
```

## Flow Description

1. **Trigger**: User or agent invokes the skill with a region parameter
2. **Auth**: Credentials auto-detected from environment variables
3. **List Buckets**: SDK `list_buckets()` → `GET /` returns all OBS buckets
4. **List Objects**: For each bucket, SDK `list_objects()` → `GET /` with pagination
5. **Excel Generation**: `openpyxl` creates a workbook with two sheets:
   - **Buckets Summary**: Bucket name, creation date, location, object count, total size
   - **Objects**: Bucket name, object key, size, ETag, last modified, storage class
6. **Output**: Excel file saved at the specified output path