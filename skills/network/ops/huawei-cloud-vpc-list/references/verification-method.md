# Verification Method — huawei-cloud-vpc-list

## 1. Prerequisites Verification

```bash
# hcloud CLI present?
hcloud version

# Authenticated?
hcloud configure list
```

## 2. Functional Verification (CLI, primary)

```bash
# List a limited number of VPCs (read-only, safe)
hcloud VPC ListVpcs/v3 --cli-region=cn-north-4 --limit=3 --cli-output=json

# Legacy v2 API
hcloud VPC ListVpcs/v2 --cli-region=cn-north-4 --limit=3 --cli-output=json
```

Expected: a JSON response with a `vpcs` array. An empty array is a valid result
(no VPCs in the project) — not an error.

## 3. Filter Verification

```bash
# Filter by name (v3)
hcloud VPC ListVpcs/v3 --cli-region=cn-north-4 --name.1=tf-web-vpc --cli-output=json

# Filter by enterprise project
hcloud VPC ListVpcs/v3 --cli-region=cn-north-4 --enterprise_project_id=all_granted_eps --cli-output=json
```

## 4. Pagination / Accurate Count Verification

```bash
# Page 1 with max limit
hcloud VPC ListVpcs/v3 --cli-region=cn-north-4 --limit=2000 --cli-output=json
# If the response contains page_info.next_marker, fetch the next page:
hcloud VPC ListVpcs/v3 --cli-region=cn-north-4 --limit=2000 --marker=<next_marker> --cli-output=json
```

The accurate total is the sum of records across all pages until no `next_marker` is returned.
`page_info.current_count` alone is the per-page count and must not be reported as the total.

## 5. SDK Fallback Verification

```python
python3 -c "
from huaweicloudsdkcore.auth.credentials import BasicCredentials
from huaweicloudsdkvpc.v3 import VpcClient, ListVpcsRequest
from huaweicloudsdkvpc.v3.region.vpc_region import VpcRegion
import os
ak = os.environ.get('HUAWEICLOUD_SDK_AK')
sk = os.environ.get('HUAWEICLOUD_SDK_SK')
creds = BasicCredentials(ak, sk)
region = VpcRegion.value_of('cn-north-4')
client = VpcClient.new_builder().with_credentials(creds).with_region(region).build()
resp = client.list_vpcs(ListVpcsRequest(limit=3))
print(len(resp.vpcs) if resp.vpcs else 0)
"
```

> Note: `with_region()` expects a `Region` object, not a plain string. Use
> `VpcRegion.value_of('cn-north-4')` (from `huaweicloudsdkvpc.v3.region.vpc_region`) as above.

## 6. Error Handling

| Symptom | Likely Cause | Action |
|---------|--------------|--------|
| Auth failure | Wrong/missing AK/SK | Re-run `hcloud configure init` |
| 403 Permission denied | Missing `vpc:vpc:list` | Attach the IAM policy from `references/iam-policies.md` |
| Region not found / empty | Wrong region or project | Confirm `--cli-region` and project id |
| Empty `vpcs` array | No VPCs in project | Valid result, not an error |
