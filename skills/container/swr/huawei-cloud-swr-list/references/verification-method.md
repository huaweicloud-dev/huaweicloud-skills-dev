# Verification Method

## Specification Compliance Verification

```bash
bash scripts/validate-skill.sh skills/container/swr/huawei-cloud-swr-list
```

This checks all items in the Huawei Cloud Skill Specification.

## Functional Testing

### CLI Mode

```bash
bash scripts/test-cli-commands.sh skills/container/swr/huawei-cloud-swr-list cli
```

Test parameters are read from `templates/test-vars.json` (region, namespace). Environment variables
`SWR_REGION` and `SWR_NAMESPACE` override them. Placeholder values such as `{region}` in the JSON
are treated as unset.

The JSON also documents all test cases used by `test-cli-commands.sh`.

### SDK Mode (Fallback)

```bash
bash scripts/test-cli-commands.sh skills/container/swr/huawei-cloud-swr-list sdk
```

**SDK response handling**: `list_repos_details()` returns a `ListReposDetailsResponse` object; the repository list is in the `.body` attribute (a flat list of `Repository` objects), not the response object itself.

```python
resp = client.list_repos_details(req)
repos = resp.body if resp and resp.body else []
names = [r.name for r in repos]
```

## Manual Verification Checklist

| # | Check | Command |
|---|-------|---------|
| 1 | List all repositories | `hcloud SWR ListReposDetails --cli-region=cn-north-4 --limit=100` |
| 2 | Filter by namespace | `hcloud SWR ListReposDetails --cli-region=cn-north-4 --namespace=group-dev --limit=100` |
| 3 | Filter by name (fuzzy) | `hcloud SWR ListReposDetails --cli-region=cn-north-4 --name=nginx --limit=100` |
| 4 | Filter by category | `hcloud SWR ListReposDetails --cli-region=cn-north-4 --category=database --limit=100` |
| 5 | Paginated listing | `hcloud SWR ListReposDetails --cli-region=cn-north-4 --limit=10 --offset=0` |
| 6 | Sorted listing | `hcloud SWR ListReposDetails --cli-region=cn-north-4 --order_column=updated_time --order_type=desc` |
| 7 | Full JSON output | `hcloud SWR ListReposDetails --cli-region=cn-north-4 --limit=100 --cli-output=json` |

## Expected Results

- All query commands return HTTP 200 with valid JSON
- Empty results are valid (no image repositories in the project/region) — response is an empty array `[]`
- The repository list response is a **flat JSON array** of repository objects; each item's `name` is the
  repository name, `namespace` is the owning organization, `category` is the repository category,
  `is_public` indicates visibility (`true`=public, `false`=private), `num_images` is the image/tag count
  (**not** `tag_count`), `size` is the total storage size in bytes, `path` is the full image path for
  `docker pull`, and `tags` is an array of tag name strings
- `--limit` and `--offset` must be used together; default limit is 100, max is 1000
- `--order_column` accepts `name`, `updated_time`, or `tag_count`; `--order_type` accepts `desc` or `asc`
