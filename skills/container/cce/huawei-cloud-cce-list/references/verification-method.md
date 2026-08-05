# Verification Method

## Specification Compliance Verification

```bash
bash scripts/validate-skill.sh skills/container/cce/huawei-cloud-cce-list
```

This checks all items in the Huawei Cloud Skill Specification.

## Functional Testing

### CLI Mode

```bash
bash scripts/test-cli-commands.sh skills/container/cce/huawei-cloud-cce-list cli
```

Test parameters are read from `templates/test-vars.json` (region). The environment
variable `CCE_REGION` overrides the region.

### SDK Mode (Fallback)

```bash
bash scripts/test-cli-commands.sh skills/container/cce/huawei-cloud-cce-list sdk
```

## Manual Verification Checklist

| # | Check | Command |
|---|-------|---------|
| 1 | List all clusters | `hcloud CCE ListClusters --cli-region=cn-north-4` |
| 2 | Cluster name list | `hcloud CCE ListClusters --cli-region=cn-north-4` piped to `jq -r '.items[].metadata.name'` |
| 3 | Filter by status | `hcloud CCE ListClusters --cli-region=cn-north-4 --status=Available` |
| 4 | Filter by type | `hcloud CCE ListClusters --cli-region=cn-north-4 --type=VirtualMachine` |
| 5 | SDK fallback | `python3` script calling `CceClient.list_clusters` |

## Expected Results

- All query commands return HTTP 200 with valid JSON
- Empty results are valid (no clusters in the project)
- The cluster list response contains an `items` array; each item's
  `metadata.name` is the cluster name, `metadata.uid` is the cluster id,
  `status.phase` is the cluster status and `spec.version` is the Kubernetes version
