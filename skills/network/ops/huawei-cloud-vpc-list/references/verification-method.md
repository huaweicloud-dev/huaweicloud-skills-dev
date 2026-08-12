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

Expected: a JSON document with a `vpcs` array containing VPC objects (id, name,
cidr, status, etc.). An empty array means the tenant has no VPCs in that region.

## 3. Functional Verification (SDK, fallback)

```bash
python3 -c "from huaweicloudsdkvpc.v3 import VpcClient; print('SDK OK')"
```

## 4. Parameter Verification

```bash
# Filter by name (v3 array syntax)
hcloud VPC ListVpcs/v3 --cli-region=cn-north-4 --limit=5 --name.1={vpc_name} --cli-output=json

# Filter by enterprise project
hcloud VPC ListVpcs/v3 --cli-region=cn-north-4 --limit=5 --enterprise_project_id=all_granted_eps --cli-output=json
```

## 5. Automated Test Cases

The test cases are stored in `templates/test-vars.json`. Run them with:

```bash
bash scripts/test-cli-commands.sh {skill-path} --executor cli
```

## 6. Read-Only Assertion

Verify that the skill only issues `GET` requests (list operations). It must never
invoke `CreateVpc`, `UpdateVpc`, or `DeleteVpc`.
