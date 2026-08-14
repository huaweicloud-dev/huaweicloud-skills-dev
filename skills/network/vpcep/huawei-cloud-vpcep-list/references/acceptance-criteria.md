# Acceptance Criteria

## Functional Criteria

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | ListEndpoints returns valid response | `hcloud VPCEP ListEndpoints --cli-region={region}` succeeds and returns the endpoint list |
| 2 | Endpoint names are present in the response | Each item's `endpoint_service_name` field is returned |
| 3 | Endpoint name-only extraction works | `hcloud VPCEP ListEndpoints --cli-region={region}` piped to `jq -r '.endpoints[].endpoint_service_name'` prints one name per line |
| 4 | ListEndpointService returns valid response | `hcloud VPCEP ListEndpointService --cli-region={region}` succeeds and returns the service list |
| 5 | Service names are present in the response | Each item's `service_name` field is returned |
| 6 | Service name-only extraction works | `hcloud VPCEP ListEndpointService --cli-region={region}` piped to `jq -r '.endpoint_services[].service_name'` prints one name per line |
| 7 | Pagination works | `hcloud VPCEP ListEndpoints --cli-region={region} --limit=10 --offset=0` succeeds |
| 8 | SDK fallback works | `VpcepClient.list_endpoints` / `list_endpoint_service` return the same lists |
| 9 | Wrapper script works | `scripts/list_vpcep.py --names-only` prints one name per line |
| 10 | Quality reporting wired | `scripts/skill_quality_sdk.py` vendored; wrapper reports via `quality_context` |

## Non-Functional Criteria

| # | Criterion | Threshold |
|---|-----------|-----------|
| 1 | All commands are read-only | No create/update/delete operations |
| 2 | CLI command response time | < 10s for list operations |
| 3 | SDK fallback works when CLI unavailable | Query methods available via SDK |
| 4 | No credential hardcoding | AK/SK from environment variables only |
| 5 | IAM least privilege | `vpcep:endpoints:list` + `vpcep:endpointServices:list` only |

## Compliance Criteria

| # | Criterion | Check |
|---|-----------|-------|
| 1 | SKILL.md frontmatter valid | name + description + tags present |
| 2 | All required sections present | Overview, Prerequisites, Workflow, Core Commands, Parameter Confirmation, Reference Documents |
| 3 | No version field in frontmatter | `version` key absent |
| 4 | File count <= 30 | Count all files in skill directory |
| 5 | SKILL.md line count <= 500 | Line count check |
