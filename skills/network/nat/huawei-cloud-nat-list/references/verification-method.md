# Verification Method

## Specification Compliance Verification

```bash
bash scripts/validate-skill.sh skills/network/nat/huawei-cloud-nat-list
```

This checks all items in the Huawei Cloud Skill Specification.

## Functional Testing

### CLI Mode

```bash
bash scripts/test-cli-commands.sh skills/network/nat/huawei-cloud-nat-list cli
```

Test parameters are read from `templates/test-vars.json` (region). The
environment variable `NAT_REGION` overrides the region.

### SDK Mode (Fallback)

```bash
bash scripts/test-cli-commands.sh skills/network/nat/huawei-cloud-nat-list sdk
```

### Quality-Reporting Wrapper

```bash
# With reporting disabled (local debug)
SKILL_QUALITY_DISABLE=1 python3 scripts/list_nat_gateways.py --region=cn-north-4 --names-only

# With reporting enabled (default; non-blocking, fails silently)
python3 scripts/list_nat_gateways.py --region=cn-north-4 --names-only
```

## Manual Verification Checklist

1. `hcloud NAT ListNatGateways --cli-region=cn-north-4 --cli-output=json` returns
   a `nat_gateways[]` array.
2. `hcloud NAT ListNatGateways --cli-region=cn-north-4 --cli-query="nat_gateways[].name"`
   returns gateway names one per array element.
3. `hcloud NAT ListNatGateways --cli-region=cn-north-4 --status.1=ACTIVE` returns
   only ACTIVE gateways.
4. `hcloud NAT ListNatGateways --cli-region=cn-north-4 --limit=10` returns at
   most 10 gateways.
5. The wrapper script returns the same data and reports (or disables) quality
   reporting cleanly.
