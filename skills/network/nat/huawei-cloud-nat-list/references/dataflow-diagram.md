# Dataflow Diagram

```mermaid
flowchart TD
    U[User / Agent] -->|request: list public NAT gateways| S[huawei-cloud-nat-list skill]
    S -->|intent + region + filters| W[Quality wrapper<br/>scripts/list_nat_gateways.py]
    W -->|quality_context start| C{hcloud CLI available?}
    C -->|yes| H[KooCLI<br/>hcloud NAT ListNatGateways<br/>--cli-region=REGION]
    C -->|no| P[huaweicloudsdknat<br/>NatClient.list_nat_gateways]
    H -->|GET /v2/{project_id}/nat_gateways| A[Huawei Cloud NAT v2 API]
    P -->|GET /v2/{project_id}/nat_gateways| A
    A -->|nat_gateways[] JSON| H
    A -->|nat_gateways[] objects| P
    H --> R[Parse & extract names<br/>.nat_gateways[].name]
    P --> R
    R -->|success / biz_fail / sys_fail| Q[skill_quality_sdk.py<br/>report to skillsopr]
    R -->|gateway names + attrs| S
    S -->|present results| U
```

## Flow Description

1. The user asks for the public NAT gateway list / gateway names (with optional
   filters: status, spec, name, enterprise project, pagination).
2. The skill resolves the region (default `cn-north-4`) and builds the query.
3. Primary path: `hcloud NAT ListNatGateways --cli-region={region}` → Huawei
   Cloud NAT v2 API `GET /v2/{project_id}/nat_gateways`.
4. Fallback path: `huaweicloudsdknat` `NatClient.list_nat_gateways` (same API).
5. The response `nat_gateways[]` is parsed; each item's `name` (plus `id`,
   `status`, `spec`, `router_id`, `internal_network_id`, `created_at`) is
   extracted and presented.
6. The quality wrapper reports the execution outcome (success/biz_fail/sys_fail,
   error code, and trace_id) to the skillsopr operations console. Reporting is
   non-blocking and fails silently.
