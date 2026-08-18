# Verification Method

## Prerequisites

- KooCLI installed and authenticated (AK/SK)
- A valid `project_id` in the target region
- (Optional but recommended) At least one WAF instance/domain in the account

## Steps

### 1. Verify CLI access to WAF service

```bash
hcloud WAF --cli-region=cn-north-4 --help
```

Expected: operation list including `ListEvent`, `ShowEvent`, `ListEventLog`, `ListStatistics`, `ListThreats`, `ListTopIp`.

### 2. Compute a time window (last 24 hours, ms timestamps)

```bash
FROM=$((($(date +%s%3N))-86400000))
TO=$(date +%s%3N)
```

### 3. Run each query and check the JSON shape

```bash
# Attack events
hcloud WAF ListEvent --cli-region=cn-north-4 --project_id=$PROJECT_ID --from=$FROM --to=$TO --pagesize=5
# Expect: {"total": N, "items": [...]}

# Access logs
hcloud WAF ListEventLog --cli-region=cn-north-4 --project_id=$PROJECT_ID --page=1 --pagesize=5
# Expect: {"total": N, "items": [...]}

# Statistics
hcloud WAF ListStatistics --cli-region=cn-north-4 --project_id=$PROJECT_ID --from=$FROM --to=$TO
# Expect: [{"key": "ACCESS", "num": N}, ...]

# Threat overview
hcloud WAF ListThreats --cli-region=cn-north-4 --project_id=$PROJECT_ID --from=$FROM --to=$TO --recent=today

# Top IPs
hcloud WAF ListTopIp --cli-region=cn-north-4 --project_id=$PROJECT_ID --from=$FROM --to=$TO
```

> If the account has no WAF instance, APIs return `{"total": 0, "items": []}` — this is a valid response, not an error.

### 4. Verify error handling

- `ListThreats` with an invalid `--recent` (e.g. `--recent=0`) must return `[USE_ERROR]` explaining valid values.
- `ListEvent` without `--from`/`--to` fails with a parameter error.
