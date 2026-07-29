# DNS API Reference Guide

## Overview

This document provides API reference information for Huawei Cloud DNS operations using hcloud CLI (KooCLI). All commands follow the standard format: `hcloud <Service> <Operation> --param=value --cli-region=<region>`.

## Authentication

### Method 1: Environment Variables

```bash
export HW_ACCESS_KEY=<your-ak>
export HW_SECRET_KEY=<your-sk>
export HW_REGION_NAME=cn-north-4
```

### Method 2: hcloud CLI Configuration

```bash
# Interactive configuration (enter credentials via prompts, not command-line arguments)
hcloud configure

# Verify configuration (safe - does not expose values)
hcloud configure list
```

✅ **Correct**: Use `hcloud configure list` to verify credentials
❌ **Incorrect**: Never use `echo $HW_ACCESS_KEY` to check credentials

## Public Zone Commands

### 1. List Public Zones

```bash
hcloud DNS ListPublicZones --cli-region=cn-north-4
```

**Response Example**:

```json
{
  "zones": [
    {
      "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "name": "example.com.",
      "status": "ACTIVE",
      "record_num": 15,
      "ttl": 300,
      "created_at": "2026-07-01T10:00:00Z",
      "updated_at": "2026-07-01T10:00:00Z"
    }
  ]
}
```

### 2. Show Public Zone Details

```bash
hcloud DNS ShowPublicZone --zone_id=<zone-id> --cli-region=cn-north-4
```

## Private Zone Commands

### 1. List Private Zones

```bash
hcloud DNS ListPrivateZones --cli-region=cn-north-4
```

### 2. Show Private Zone Details

```bash
hcloud DNS ShowPrivateZone --zone_id=<zone-id> --cli-region=cn-north-4
```

## Public Record Set Commands

### 1. List Record Sets

```bash
hcloud DNS ListRecordSets --zone_id=<zone-id> --cli-region=cn-north-4
```

**Parameters**:
- `--zone_id` (required): Zone ID
- `--limit` (optional): Maximum number of results
- `--offset` (optional): Pagination offset
- `--type` (optional): Filter by record type
- `--name` (optional): Filter by record set name

**Response Example**:

```json
{
  "recordsets": [
    {
      "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "name": "www.example.com.",
      "type": "A",
      "ttl": 300,
      "status": "ACTIVE",
      "records": ["192.168.1.100"],
      "zone_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "zone_name": "example.com."
    }
  ]
}
```

### 2. Show Record Set Details

```bash
hcloud DNS ShowRecordSet --zone_id=<zone-id> --recordset_id=<recordset-id> --cli-region=cn-north-4
```

### 3. Create Record Set

```bash
hcloud DNS CreateRecordSet \
  --zone_id=<zone-id> \
  --name=www.example.com. \
  --type=A \
  --records=192.168.1.100 \
  --ttl=300 \
  --cli-region=cn-north-4
```

**Parameters**:
- `--zone_id` (required): Zone ID
- `--name` (required): Record set name (FQDN with trailing dot)
- `--type` (required): Record type (A, AAAA, CNAME, MX, TXT, NS, SRV, CAA)
- `--records` (required): Record value(s)
- `--ttl` (optional): TTL in seconds (default: 300)
- `--description` (optional): Record set description

### 4. Update Record Set

```bash
hcloud DNS UpdateRecordSet \
  --zone_id=<zone-id> \
  --recordset_id=<recordset-id> \
  --name=www.example.com. \
  --type=A \
  --records=192.168.2.200 \
  --ttl=300 \
  --cli-region=cn-north-4
```

### 5. Delete Record Set

```bash
hcloud DNS DeleteRecordSet \
  --zone_id=<zone-id> \
  --recordset_id=<recordset-id> \
  --cli-region=cn-north-4
```

⚠️ **Warning**: This operation is irreversible. The DNS record will be permanently removed.

## Private Record Set Commands

### 1. List Private Record Sets

```bash
hcloud DNS ListPrivateRecordSets --zone_id=<zone-id> --cli-region=cn-north-4
```

### 2. Create Private Record Set

```bash
hcloud DNS CreatePrivateRecordSet \
  --zone_id=<zone-id> \
  --name=app.internal.example.com. \
  --type=A \
  --records=10.0.1.100 \
  --ttl=300 \
  --cli-region=cn-north-4
```

### 3. Update Private Record Set

```bash
hcloud DNS UpdatePrivateRecordSet \
  --zone_id=<zone-id> \
  --recordset_id=<recordset-id> \
  --name=app.internal.example.com. \
  --type=A \
  --records=10.0.1.200 \
  --ttl=300 \
  --cli-region=cn-north-4
```

### 4. Delete Private Record Set

```bash
hcloud DNS DeletePrivateRecordSet \
  --zone_id=<zone-id> \
  --recordset_id=<recordset-id> \
  --cli-region=cn-north-4
```

## Record Types Reference

| Type | Description | Value Format | Example |
|------|-------------|--------------|---------|
| A | IPv4 address | IP address | `192.168.1.100` |
| AAAA | IPv6 address | IPv6 address | `2001:db8::1` |
| CNAME | Canonical name | FQDN with trailing dot | `lb.example.com.` |
| MX | Mail exchange | Priority + FQDN | `10 mail.example.com.` |
| TXT | Text record | Quoted text | `"verification-token"` |
| NS | Name server | FQDN with trailing dot | `ns1.example.com.` |
| SRV | Service record | Priority Weight Port Target | `10 5 5060 sip.example.com.` |
| CAA | Certification Authority Authorization | Flag Tag Value | `0 issue "ca.example.com"` |

## Common Region IDs

| Region Name | Region ID |
|-------------|-----------|
| North China - Beijing 4 | `cn-north-4` |
| North China - Beijing 1 | `cn-north-1` |
| East China - Shanghai 1 | `cn-east-3` |
| South China - Guangzhou | `cn-south-1` |
| Asia Pacific - Hong Kong | `ap-southeast-1` |
| Asia Pacific - Singapore | `ap-southeast-2` |
| Europe - Paris | `eu-west-0` |

## Zone Status Reference

| Status | Description |
|--------|-------------|
| `ACTIVE` | Zone is active and resolving |
| `FREEZED` | Zone is frozen |
| `DISABLE` | Zone is disabled |

## Record Set Status Reference

| Status | Description |
|--------|-------------|
| `ACTIVE` | Record set is active |
| `FREEZED` | Record set is frozen |
| `DISABLE` | Record set is disabled |
| `SUSPEND` | Record set is suspended |

## Best Practices

1. **Use FQDN**: Always include trailing dot in record names (e.g., `www.example.com.`)
2. **Low TTL for Dynamic Records**: Use 60-300s TTL for records that change frequently
3. **Backup Before Changes**: Export current records before batch updates
4. **Validate After Update**: Use `validate_dns.sh` to confirm DNS propagation
5. **Audit All Changes**: Log all DNS operations for compliance

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `InvalidAccessKeyId` | Invalid AK/SK | Check credential configuration |
| `DNS.0301` | Zone does not exist | Verify zone name is correct with trailing dot |
| `DNS.0302` | Record set already exists | Use update instead of create |
| `DNS.0303` | Record set not found | Verify record name and type |
| `DNS.0304` | Invalid record value | Check value format matches record type |
| `429` | Too many requests | Add delay between API calls |

## Related Documentation

- [Huawei Cloud DNS Documentation](https://support.huaweicloud.com/dns/index.html)
- [KooCLI Documentation](https://support.huaweicloud.com/cli/index.html)
- [Huawei Cloud API Explorer](https://apiexplorer.developer.huaweicloud.com/)
