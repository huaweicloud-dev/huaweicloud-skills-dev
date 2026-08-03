# Verification Method

## Specification Compliance Verification

```bash
bash scripts/validate-skill.sh skills/bigdata/css/huawei-cloud-css-list
```

This checks all items in the Huawei Cloud Skill Specification.

## Functional Testing

### CLI Mode

```bash
bash scripts/test-cli-commands.sh skills/bigdata/css/huawei-cloud-css-list cli
```

Test parameters are read from `templates/test-vars.json` (region). Environment variables
`CSS_REGION` override them. Placeholder values such as `{region}` in the JSON
are treated as unset.

The JSON also documents all test cases used by `test-cli-commands.sh`.

### SDK Mode (Fallback)

```bash
bash scripts/test-cli-commands.sh skills/bigdata/css/huawei-cloud-css-list sdk
```

## Manual Verification Checklist

| # | Check | Command |
|---|-------|---------|
| 1 | List all ES clusters | `hcloud CSS ListClustersDetails --cli-region=cn-north-4 --limit=100` |
| 2 | Filter by engine type | `hcloud CSS ListClustersDetails --cli-region=cn-north-4 --datastoreType=elasticsearch --limit=100` |
| 3 | Paginated listing | `hcloud CSS ListClustersDetails --cli-region=cn-north-4 --limit=10 --offset=1` |
| 4 | Full JSON output | `hcloud CSS ListClustersDetails --cli-region=cn-north-4 --limit=100 --cli-output=json` |
| 5 | Filter by opensearch engine | `hcloud CSS ListClustersDetails --cli-region=cn-north-4 --datastoreType=opensearch --limit=100` |

## Expected Results

- All query commands return HTTP 200 with valid JSON
- Empty results are valid (no ES clusters in the project/region)
- The cluster list response contains a `totalSize` field (cluster count) and a `clusters` array; each
  item's `id` is the cluster ID, `name` is the cluster name, `status` is the cluster status (`100`
  creating, `200` available, `300` unavailable, `303` creation failed), `endpoint` is the access
  address, and `datastore` describes the engine and version
- `--datastoreType` accepts `elasticsearch`, `logstash`, or `opensearch`; omit it to list all cluster types
