# Verification Method

## Specification Compliance Verification

```bash
bash scripts/validate-skill.sh skills/container/cce/huawei-cloud-cce-query
```

This checks all items in the Huawei Cloud Skill Specification.

## Functional Testing

### CLI Mode

```bash
bash scripts/test-cli-commands.sh skills/container/cce/huawei-cloud-cce-query cli
```

Test parameters are read from `templates/test-vars.json` (region, cluster_id). Environment variables
`CCE_REGION`, `CCE_CLUSTER_ID` override them. Placeholder values such as `{cluster_id}` in the JSON
are treated as unset.

The JSON also documents all test cases used by `test-cli-commands.sh`.

### SDK Mode (Fallback)

```bash
bash scripts/test-cli-commands.sh skills/container/cce/huawei-cloud-cce-query sdk
```

## Manual Verification Checklist

| # | Check | Command |
|---|-------|---------|
| 1 | List all clusters | `hcloud CCE ListClusters --cli-region=cn-north-4` |
| 2 | List clusters filtered by status | `hcloud CCE ListClusters --cli-region=cn-north-4 --status=Available` |
| 3 | List clusters with detail | `hcloud CCE ListClusters --cli-region=cn-north-4 --detail=true` |
| 4 | Show cluster detail | `hcloud CCE ShowCluster --cli-region=cn-north-4 --cluster_id=<cluster_id>` |
| 5 | List nodes of a cluster | `hcloud CCE ListNodes --cli-region=cn-north-4 --cluster_id=<cluster_id>` |

## Expected Results

- All query commands return HTTP 200 with valid JSON
- Empty results are valid (no clusters/nodes in the project)
- `ShowCluster` and `ListNodes` require an existing `cluster_id`
- The cluster list response contains an `items` array; each item's `metadata.name` is the cluster name and `status.phase` is the cluster status
