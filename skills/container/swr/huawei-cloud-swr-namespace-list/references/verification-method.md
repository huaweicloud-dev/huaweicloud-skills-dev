# Verification Method

## Specification Compliance Verification

```bash
bash scripts/validate-skill.sh skills/container/swr/huawei-cloud-swr-namespace-list
```

This checks all items in the Huawei Cloud Skill Specification.

## Functional Testing

### CLI Mode

```bash
bash scripts/test-cli-commands.sh skills/container/swr/huawei-cloud-swr-namespace-list cli
```

Test parameters are read from `templates/test-vars.json` (region, namespace). Environment variables
`SWR_REGION` and `SWR_NAMESPACE` override them. Placeholder values such as `{region}` in the JSON
are treated as unset.

The JSON also documents all test cases used by `test-cli-commands.sh`.

### SDK Mode (Fallback)

```bash
bash scripts/test-cli-commands.sh skills/container/swr/huawei-cloud-swr-namespace-list sdk
```

**SDK response handling**: `list_namespaces()` returns a `ListNamespacesResponse` object; the namespace list is in the `.namespaces` attribute (a list of `Namespace` objects), not the response object itself.

```python
resp = client.list_namespaces(req)
namespaces = resp.namespaces if resp and resp.namespaces else []
names = [ns.name for ns in namespaces]
```

## Manual Verification Checklist

| # | Check | Command |
|---|-------|---------|
| 1 | List all namespaces | `hcloud SWR ListNamespaces --cli-region=cn-north-4` |
| 2 | Filter by namespace name | `hcloud SWR ListNamespaces --cli-region=cn-north-4 --namespace=group-dev` |
| 3 | Full JSON output | `hcloud SWR ListNamespaces --cli-region=cn-north-4 --cli-output=json` |

## Expected Results

- All query commands return HTTP 200 with valid JSON
- Empty results are valid (no SWR namespaces in the project/region) — response contains an empty `namespaces` array
- The namespace list response contains a `namespaces` array; each item's `id` is the numeric namespace
  ID, `name` is the namespace name, `creator_name` is the creator IAM user name, `auth` is the
  permission level (7=manage, 3=edit, 1=read), `access_user_count` is the number of users with
  access, and `repo_count` is the number of repositories under this namespace
- `ListNamespaces` does not support pagination (`--limit`/`--offset`); it returns all namespaces
