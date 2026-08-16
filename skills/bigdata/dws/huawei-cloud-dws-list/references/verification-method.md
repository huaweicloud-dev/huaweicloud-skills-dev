# Verification Method

## Functional Verification

### 1. Command Existence

```bash
hcloud DWS ListClusters --cli-region=cn-north-4 --help
```

Expected: help text shown, exit code 0.

### 2. Live Execution

```bash
hcloud DWS ListClusters --cli-region=cn-north-4 | jq -r '.clusters[]?.name'
```

Expected: prints each DWS cluster name on its own line. If no clusters exist, prints nothing and the raw JSON is `{"clusters": [], "count": 0}`.

### 3. Empty Result Handling

```bash
hcloud DWS ListClusters --cli-region=cn-north-4
```

Expected: valid JSON output, exit code 0.

## Test Cases

See `templates/test-vars.json` for the full case list. Run via:

```bash
bash scripts/test-cli-commands.sh <skill-path> --executor cli
```
