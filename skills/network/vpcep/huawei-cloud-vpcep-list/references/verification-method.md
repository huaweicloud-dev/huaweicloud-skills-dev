# Verification Method

## Specification Compliance Verification

```bash
bash scripts/validate-skill.sh skills/network/vpcep/huawei-cloud-vpcep-list
```

This checks all items in the Huawei Cloud Skill Specification.

## Functional Testing

### CLI Mode

```bash
bash scripts/test-cli-commands.sh skills/network/vpcep/huawei-cloud-vpcep-list cli
```

Test parameters are read from `templates/test-vars.json` (region). The
environment variable `VPCEP_REGION` overrides the region.

### SDK Mode (Fallback)

```bash
bash scripts/test-cli-commands.sh skills/network/vpcep/huawei-cloud-vpcep-list sdk
```

## Manual Verification Checklist

| # | Check | Command |
|---|-------|---------|
| 1 | List all endpoints | `hcloud VPCEP ListEndpoints --cli-region=cn-north-4` |
| 2 | Endpoint name list | `hcloud VPCEP ListEndpoints --cli-region=cn-north-4` piped to `jq -r '.endpoints[].endpoint_service_name'` |
| 3 | Filter by service name | `hcloud VPCEP ListEndpoints --cli-region=cn-north-4 --endpoint_service_name=my-service` |
| 4 | Pagination | `hcloud VPCEP ListEndpoints --cli-region=cn-north-4 --limit=10 --offset=0` |
| 5 | List all endpoint services | `hcloud VPCEP ListEndpointService --cli-region=cn-north-4` |
| 6 | Service name list | `hcloud VPCEP ListEndpointService --cli-region=cn-north-4` piped to `jq -r '.endpoint_services[].service_name'` |
| 7 | SDK fallback | `python3` script calling `VpcepClient.list_endpoints` / `list_endpoint_service` |
| 8 | Wrapper script | `SKILL_QUALITY_DISABLE=1 python3 scripts/list_vpcep.py --names-only` prints endpoint names |

## Expected Results

- All query commands return HTTP 200 with valid JSON
- Empty results are valid (no VPCEP resource in the project)
- `ListEndpoints` returns an `endpoints` array; each item's
  `endpoint_service_name` is the endpoint display name, `id` is the endpoint
  id, `status` is the endpoint status
- `ListEndpointService` returns an `endpoint_services` array; each item's
  `service_name` is the service name, `id` is the service id, `status` is the
  service status
